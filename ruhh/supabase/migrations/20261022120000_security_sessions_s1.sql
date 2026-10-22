-- S1 (additive, backward compatible): security hardening + server-side PIN sessions.
-- Legacy v1 RPCs (ruhh_fetch_auth_profile, ruhh_pull, ruhh_push, ruhh_register_user) are
-- intentionally left unchanged so already-installed app versions keep working.
-- Retirement of the legacy path lives in supabase/pending/ (S2) and must NOT be applied
-- until the R1 app release is adopted (see docs/SECURITY_ROLLOUT.md).

create extension if not exists "pgcrypto";

-- 1. Budget tables: enable RLS (no FORCE, so SECURITY DEFINER sync RPCs owned by the
--    table owner keep working) and remove direct API access.
alter table public.budget_objectives enable row level security;
alter table public.category_budget_limits enable row level security;
revoke all on public.budget_objectives from anon, authenticated;
revoke all on public.category_budget_limits from anon, authenticated;

-- 2. ruhh_verify_user is an internal helper: nobody outside the owner may call it.
revoke execute on function public.ruhh_verify_user(uuid, text) from public, anon, authenticated;

-- 3. Server-side PIN verifier (bcrypt). Legacy pin_hash/pin_salt are kept for old clients.
alter table public.users add column if not exists pin_bcrypt text;

-- 4. Config (minimum supported client version etc.)
create table if not exists public.ruhh_app_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);
insert into public.ruhh_app_config (key, value)
values ('min_supported_version', '0.0.0'), ('session_ttl_days', '30')
on conflict (key) do nothing;

-- 5. Sessions (only the SHA-256 of the token is stored).
create table if not exists public.ruhh_sessions (
  id uuid primary key default gen_random_uuid(),
  token_hash text not null unique,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  client_version text
);
create index if not exists ruhh_sessions_user_idx on public.ruhh_sessions (user_id);

-- 6. Login attempts for lockout (keyed by normalised username, also for unknown users).
create table if not exists public.ruhh_login_attempts (
  id bigint generated always as identity primary key,
  username_key text not null,
  success boolean not null,
  created_at timestamptz not null default now()
);
create index if not exists ruhh_login_attempts_key_idx
  on public.ruhh_login_attempts (username_key, created_at desc);

alter table public.ruhh_app_config enable row level security;
alter table public.ruhh_sessions enable row level security;
alter table public.ruhh_login_attempts enable row level security;
revoke all on public.ruhh_app_config from public, anon, authenticated;
revoke all on public.ruhh_sessions from public, anon, authenticated;
revoke all on public.ruhh_login_attempts from public, anon, authenticated;

-- ---------- internal helpers (not granted to API roles) ----------

create or replace function public.ruhh_version_lt(a text, b text)
returns boolean
language sql
immutable
set search_path = public
as $$
  select coalesce(
    (
      select (array[
        coalesce(nullif(split_part(split_part(a, '+', 1), '.', 1), ''), '0')::int,
        coalesce(nullif(split_part(split_part(a, '+', 1), '.', 2), ''), '0')::int,
        coalesce(nullif(split_part(split_part(a, '+', 1), '.', 3), ''), '0')::int
      ]) < (array[
        coalesce(nullif(split_part(split_part(b, '+', 1), '.', 1), ''), '0')::int,
        coalesce(nullif(split_part(split_part(b, '+', 1), '.', 2), ''), '0')::int,
        coalesce(nullif(split_part(split_part(b, '+', 1), '.', 3), ''), '0')::int
      ])
      where a ~ '^[0-9]+(\.[0-9]+){0,2}(\+[0-9]+)?$'
    ),
    true
  );
$$;

create or replace function public.ruhh_config(p_key text, p_default text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select value from public.ruhh_app_config where key = p_key), p_default);
$$;

create or replace function public.ruhh_token_hash(p_token text)
returns text
language sql
immutable
set search_path = public, extensions
as $$
  select encode(extensions.digest(convert_to(coalesce(p_token, ''), 'UTF8'), 'sha256'), 'hex');
$$;

-- Resolves a bearer session token to a user id or raises 'session_invalid'.
create or replace function public.ruhh_session_user(p_token text)
returns uuid
language plpgsql
stable
security definer
set search_path = public, extensions
as $$
declare
  v_user uuid;
begin
  if p_token is null or p_token !~ '^[0-9a-f]{64}$' then
    raise exception 'session_invalid' using errcode = '28000';
  end if;
  select s.user_id into v_user
  from public.ruhh_sessions s
  where s.token_hash = public.ruhh_token_hash(p_token)
    and s.revoked_at is null
    and s.expires_at > now();
  if v_user is null then
    raise exception 'session_invalid' using errcode = '28000';
  end if;
  return v_user;
end;
$$;

create or replace function public.ruhh_issue_session(p_user uuid, p_client_version text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_token text := encode(extensions.gen_random_bytes(32), 'hex');
  v_exp timestamptz := now() + make_interval(days => public.ruhh_config('session_ttl_days', '30')::int);
begin
  insert into public.ruhh_sessions (token_hash, user_id, expires_at, client_version)
  values (public.ruhh_token_hash(v_token), p_user, v_exp, left(p_client_version, 32));
  return jsonb_build_object('token', v_token, 'expires_at', v_exp);
end;
$$;

-- ---------- public v2 API ----------

create or replace function public.ruhh_login(
  p_username text,
  p_pin text,
  p_client_version text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_key text := lower(trim(coalesce(p_username, '')));
  v_min text := public.ruhh_config('min_supported_version', '0.0.0');
  v_fails int;
  v_user public.users%rowtype;
  v_ok boolean := false;
  v_session jsonb;
begin
  if public.ruhh_version_lt(p_client_version, v_min) then
    return jsonb_build_object('ok', false, 'error', 'update_required',
      'min_supported_version', v_min);
  end if;

  select count(*) into v_fails
  from public.ruhh_login_attempts a
  where a.username_key = v_key
    and a.success = false
    and a.created_at > now() - interval '15 minutes';
  if v_fails >= 5 then
    return jsonb_build_object('ok', false, 'error', 'locked_out', 'retry_after_seconds', 900);
  end if;

  select * into v_user from public.users u where lower(u.username) = v_key;

  if v_user.id is not null and coalesce(p_pin, '') ~ '^[0-9]{4,12}$' then
    if v_user.pin_bcrypt is not null then
      v_ok := extensions.crypt(p_pin, v_user.pin_bcrypt) = v_user.pin_bcrypt;
    else
      v_ok := encode(extensions.digest(convert_to(v_user.pin_salt || ':' || p_pin, 'UTF8'), 'sha256'), 'hex')
              = v_user.pin_hash;
    end if;
  else
    -- equalise work for unknown users / malformed PINs
    perform extensions.crypt(coalesce(p_pin, ''), '$2a$10$abcdefghijklmnopqrstuu');
  end if;

  if not v_ok then
    insert into public.ruhh_login_attempts (username_key, success) values (v_key, false);
    return jsonb_build_object('ok', false, 'error', 'invalid_credentials');
  end if;

  delete from public.ruhh_login_attempts a where a.username_key = v_key and a.success = false;
  insert into public.ruhh_login_attempts (username_key, success) values (v_key, true);

  if v_user.pin_bcrypt is null then
    update public.users set pin_bcrypt = extensions.crypt(p_pin, extensions.gen_salt('bf', 10))
    where id = v_user.id;
  end if;

  v_session := public.ruhh_issue_session(v_user.id, p_client_version);
  return jsonb_build_object(
    'ok', true,
    'token', v_session->>'token',
    'expires_at', v_session->>'expires_at',
    'user_id', v_user.id,
    'username', v_user.username,
    'pin_salt', v_user.pin_salt,
    'min_supported_version', v_min
  );
end;
$$;

create or replace function public.ruhh_register_user_v2(
  p_id uuid,
  p_username text,
  p_pin text,
  p_client_version text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_username text := lower(trim(coalesce(p_username, '')));
  v_min text := public.ruhh_config('min_supported_version', '0.0.0');
  v_salt text;
  v_session jsonb;
begin
  if public.ruhh_version_lt(p_client_version, v_min) then
    return jsonb_build_object('ok', false, 'error', 'update_required',
      'min_supported_version', v_min);
  end if;
  if char_length(v_username) < 3 or char_length(v_username) > 64 then
    return jsonb_build_object('ok', false, 'error', 'username_too_short');
  end if;
  if coalesce(p_pin, '') !~ '^[0-9]{4,12}$' then
    return jsonb_build_object('ok', false, 'error', 'invalid_pin');
  end if;
  if p_id is null or exists (select 1 from public.users u where u.id = p_id) then
    return jsonb_build_object('ok', false, 'error', 'invalid_id');
  end if;
  if exists (select 1 from public.users u where lower(u.username) = v_username) then
    return jsonb_build_object('ok', false, 'error', 'username_taken');
  end if;

  -- same salt shape as the app's base64UrlEncode(16 random bytes)
  v_salt := translate(encode(extensions.gen_random_bytes(16), 'base64'), '+/', '-_');

  insert into public.users (id, username, pin_hash, pin_salt, pin_bcrypt)
  values (
    p_id,
    v_username,
    encode(extensions.digest(convert_to(v_salt || ':' || p_pin, 'UTF8'), 'sha256'), 'hex'),
    v_salt,
    extensions.crypt(p_pin, extensions.gen_salt('bf', 10))
  );

  v_session := public.ruhh_issue_session(p_id, p_client_version);
  return jsonb_build_object(
    'ok', true,
    'token', v_session->>'token',
    'expires_at', v_session->>'expires_at',
    'user_id', p_id,
    'username', v_username,
    'pin_salt', v_salt,
    'min_supported_version', v_min
  );
end;
$$;

create or replace function public.ruhh_logout(p_token text)
returns boolean
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
begin
  update public.ruhh_sessions
  set revoked_at = now()
  where token_hash = public.ruhh_token_hash(p_token) and revoked_at is null;
  return found;
end;
$$;

-- v2 sync delegates to the v1 implementation (identical semantics: full-snapshot
-- reconcile + empty-payload guard) after resolving the session server-side.
create or replace function public.ruhh_pull_v2(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := public.ruhh_session_user(p_token);
begin
  return public.ruhh_pull(v_user, (select u.pin_hash from public.users u where u.id = v_user));
end;
$$;

create or replace function public.ruhh_push_v2(p_token text, p_payload jsonb)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := public.ruhh_session_user(p_token);
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'invalid_payload' using errcode = '22023';
  end if;
  perform public.ruhh_push(v_user, (select u.pin_hash from public.users u where u.id = v_user), p_payload);
end;
$$;

create or replace function public.ruhh_session_info_v2(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := public.ruhh_session_user(p_token);
begin
  return jsonb_build_object(
    'user_id', v_user,
    'expires_at', (select max(expires_at) from public.ruhh_sessions
                   where token_hash = public.ruhh_token_hash(p_token)),
    'min_supported_version', public.ruhh_config('min_supported_version', '0.0.0')
  );
end;
$$;

-- ---------- grants ----------
revoke all on function public.ruhh_version_lt(text, text) from public, anon, authenticated;
revoke all on function public.ruhh_config(text, text) from public, anon, authenticated;
revoke all on function public.ruhh_token_hash(text) from public, anon, authenticated;
revoke all on function public.ruhh_session_user(text) from public, anon, authenticated;
revoke all on function public.ruhh_issue_session(uuid, text) from public, anon, authenticated;

revoke all on function public.ruhh_login(text, text, text) from public;
revoke all on function public.ruhh_register_user_v2(uuid, text, text, text) from public;
revoke all on function public.ruhh_logout(text) from public;
revoke all on function public.ruhh_pull_v2(text) from public;
revoke all on function public.ruhh_push_v2(text, jsonb) from public;
revoke all on function public.ruhh_session_info_v2(text) from public;

grant execute on function public.ruhh_login(text, text, text) to anon, authenticated;
grant execute on function public.ruhh_register_user_v2(uuid, text, text, text) to anon, authenticated;
grant execute on function public.ruhh_logout(text) to anon, authenticated;
grant execute on function public.ruhh_pull_v2(text) to anon, authenticated;
grant execute on function public.ruhh_push_v2(text, jsonb) to anon, authenticated;
grant execute on function public.ruhh_session_info_v2(text) to anon, authenticated;
