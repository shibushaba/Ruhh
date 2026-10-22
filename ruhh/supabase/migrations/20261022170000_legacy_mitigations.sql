-- Interim, compatibility-safe mitigations for the LEGACY (v1) API used by pre-R1 apps.
--
-- These DO NOT remove the pass-the-hash exposure: until S2 (supabase/pending/S2_retire_legacy_auth.sql)
-- anyone can still call ruhh_fetch_auth_profile for a username and use the returned pin_hash with
-- ruhh_pull / ruhh_push. They only (a) make bulk harvesting slower and visible, (b) bound how often
-- a hash can be used, and (c) stop a single forged push from wiping most of an account.
-- Old app behaviour is unchanged for normal use (verified by supabase/tests/07_legacy_mitigations_test.sql).
--
-- Limits (per rolling hour):
--   ruhh_fetch_auth_profile: 20 per username, 1000 globally  (old app calls it once per new-device login)
--   ruhh_pull / ruhh_push (v1): 1200 per user id              (old app: ~1-3 calls per sync, ~1 sync/min)
-- Logging: every ACCEPTED call is recorded (fn, username/user id, gateway IP). A call that raises
-- (wrong hash, rate limited, blocked) rolls its own log row back, so only successful uses count
-- against the limits; refused fetch_auth_profile calls ARE logged ('limited').
-- Mass-deletion guard on v1 ruhh_push: refuse when a push would delete more than 50 rows AND more than
-- 50% of the user's existing synced rows (habit completions of a habit deleted in the same push are
-- not counted, so deleting a habit with a long history still works). v2 (R1 app) is not affected.

create table if not exists public.ruhh_legacy_calls (
  id bigint generated always as identity primary key,
  fn text not null check (fn in ('fetch_auth_profile', 'pull', 'push')),
  key text not null check (char_length(key) <= 80),
  outcome text not null check (outcome in ('ok', 'limited', 'blocked')),
  ip text check (ip is null or char_length(ip) <= 64),
  created_at timestamptz not null default now()
);
create index if not exists ruhh_legacy_calls_key_idx on public.ruhh_legacy_calls (fn, key, created_at);
create index if not exists ruhh_legacy_calls_time_idx on public.ruhh_legacy_calls (fn, created_at);
alter table public.ruhh_legacy_calls enable row level security;
revoke all on public.ruhh_legacy_calls from public, anon, authenticated;

-- Records one legacy call (metadata only: function, username/user id, client IP from the API gateway).
-- Also prunes rows older than 2 days now and then, so the table stays small without cron.
create or replace function public.ruhh_legacy_note(p_fn text, p_key text, p_outcome text)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_ip text;
begin
  begin
    v_ip := left(split_part(coalesce(
      current_setting('request.headers', true)::json->>'x-forwarded-for', ''), ',', 1), 64);
  exception when others then
    v_ip := null;
  end;
  insert into public.ruhh_legacy_calls (fn, key, outcome, ip)
  values (p_fn, left(coalesce(p_key, ''), 80), p_outcome, nullif(trim(v_ip), ''));
  if random() < 0.01 then
    delete from public.ruhh_legacy_calls where created_at < now() - interval '2 days';
  end if;
end;
$$;

create or replace function public.ruhh_legacy_recent(p_fn text, p_key text)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::int from public.ruhh_legacy_calls
  where fn = p_fn and (p_key is null or key = p_key) and created_at > now() - interval '1 hour';
$$;

-- ---------- ruhh_fetch_auth_profile: same output, now rate limited + logged ----------
create or replace function public.ruhh_fetch_auth_profile(p_username text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_key text := lower(trim(coalesce(p_username, '')));
begin
  if char_length(v_key) > 80 then
    return 'null'::jsonb;
  end if;
  if public.ruhh_legacy_recent('fetch_auth_profile', v_key) >= 20
     or public.ruhh_legacy_recent('fetch_auth_profile', null) >= 1000 then
    perform public.ruhh_legacy_note('fetch_auth_profile', v_key, 'limited');
    return 'null'::jsonb; -- old app shows "User not found"; try again later
  end if;
  perform public.ruhh_legacy_note('fetch_auth_profile', v_key, 'ok');
  return coalesce(
    (
      select jsonb_build_object(
        'id', u.id,
        'username', u.username,
        'pin_hash', u.pin_hash,
        'pin_salt', u.pin_salt
      )
      from public.users u
      where lower(u.username) = v_key
    ),
    'null'::jsonb
  );
end;
$$;

-- ---------- v1 pull/push: keep the implementation, wrap it ----------
-- The implementations are renamed to *_core (internal). The public v1 names become thin wrappers
-- with the same signatures, so old apps call exactly what they called before.
alter function public.ruhh_pull(uuid, text) rename to ruhh_pull_core;
alter function public.ruhh_push(uuid, text, jsonb) rename to ruhh_push_core;
revoke all on function public.ruhh_pull_core(uuid, text) from public, anon, authenticated;
revoke all on function public.ruhh_push_core(uuid, text, jsonb) from public, anon, authenticated;

create or replace function public.ruhh_pull(p_user_id uuid, p_pin_hash text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  if public.ruhh_legacy_recent('pull', p_user_id::text) >= 1200 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  perform public.ruhh_legacy_note('pull', coalesce(p_user_id::text, ''), 'ok');
  return public.ruhh_pull_core(p_user_id, p_pin_hash);
end;
$$;

-- Rows a v1 push would delete (same rule as ruhh_push_core) versus the user's existing rows.
create or replace function public.ruhh_push_deletion_stats(p_user_id uuid, p_payload jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_existing int := 0;
  v_deleted int := 0;
  v_n int;
  v_has boolean;
  t text;
  tables text[] := array['objectives:budget_objectives', 'category_budget_limits:category_budget_limits',
    'transactions:transactions', 'habits:habits', 'prayer_logs:prayer_logs', 'movies:movies'];
  v_key text;
  v_tab text;
begin
  v_has :=
    jsonb_array_length(coalesce(p_payload->'objectives', '[]'::jsonb)) > 0
    or jsonb_array_length(coalesce(p_payload->'category_budget_limits', '[]'::jsonb)) > 0
    or jsonb_array_length(coalesce(p_payload->'transactions', '[]'::jsonb)) > 0
    or jsonb_array_length(coalesce(p_payload->'habits', '[]'::jsonb)) > 0
    or jsonb_array_length(coalesce(p_payload->'habit_completions', '[]'::jsonb)) > 0
    or jsonb_array_length(coalesce(p_payload->'prayer_logs', '[]'::jsonb)) > 0
    or jsonb_array_length(coalesce(p_payload->'movies', '[]'::jsonb)) > 0;
  if not v_has then
    return jsonb_build_object('existing', 0, 'deleted', 0); -- empty-payload guard: nothing deleted
  end if;

  foreach t in array tables loop
    v_key := split_part(t, ':', 1);
    v_tab := split_part(t, ':', 2);
    execute format('select count(*) from public.%I where user_id = $1', v_tab) into v_n using p_user_id;
    v_existing := v_existing + v_n;
    execute format($q$
      select count(*) from public.%I x
      where x.user_id = $1 and not exists (
        select 1 from jsonb_array_elements(coalesce($2->%L, '[]'::jsonb)) e
        where (e->>'id') = x.id::text)$q$, v_tab, v_key)
    into v_n using p_user_id, p_payload;
    v_deleted := v_deleted + v_n;
  end loop;

  -- completions: count existing, but only count deletions whose habit survives the push
  select count(*) into v_n from public.habit_completions c where c.user_id = p_user_id;
  v_existing := v_existing + v_n;
  select count(*) into v_n from public.habit_completions c
  where c.user_id = p_user_id
    and not exists (select 1 from jsonb_array_elements(coalesce(p_payload->'habit_completions', '[]'::jsonb)) e
                    where (e->>'id') = c.id::text)
    and exists (select 1 from jsonb_array_elements(coalesce(p_payload->'habits', '[]'::jsonb)) h
                where (h->>'id') = c.habit_id::text);
  v_deleted := v_deleted + v_n;

  return jsonb_build_object('existing', v_existing, 'deleted', v_deleted);
end;
$$;

create or replace function public.ruhh_push(p_user_id uuid, p_pin_hash text, p_payload jsonb)
returns void
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_stats jsonb;
begin
  if not public.ruhh_verify_user(p_user_id, p_pin_hash) then
    raise exception 'unauthorized';
  end if;
  if public.ruhh_legacy_recent('push', p_user_id::text) >= 1200 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  v_stats := public.ruhh_push_deletion_stats(p_user_id, p_payload);
  if (v_stats->>'deleted')::int > 50
     and (v_stats->>'deleted')::int * 2 > (v_stats->>'existing')::int then
    raise exception 'mass_delete_blocked' using errcode = 'P0001',
      hint = 'Update the RUHH app to the latest version to continue cloud backup.';
  end if;
  perform public.ruhh_legacy_note('push', p_user_id::text, 'ok');
  perform public.ruhh_push_core(p_user_id, p_pin_hash, p_payload);
end;
$$;

-- v2 (R1 app, session-authenticated) keeps calling the implementation directly:
-- no legacy rate limit and no mass-deletion guard (R1 is the supported path).
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
  return public.ruhh_pull_core(v_user, (select u.pin_hash from public.users u where u.id = v_user));
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
  perform public.ruhh_push_core(v_user, (select u.pin_hash from public.users u where u.id = v_user), p_payload);
end;
$$;

revoke all on function public.ruhh_legacy_note(text, text, text) from public, anon, authenticated;
revoke all on function public.ruhh_legacy_recent(text, text) from public, anon, authenticated;
revoke all on function public.ruhh_push_deletion_stats(uuid, jsonb) from public, anon, authenticated;
-- public v1 names keep exactly the grants old apps rely on (until S2 revokes them)
revoke all on function public.ruhh_fetch_auth_profile(text) from public;
revoke all on function public.ruhh_pull(uuid, text) from public;
revoke all on function public.ruhh_push(uuid, text, jsonb) from public;
grant execute on function public.ruhh_fetch_auth_profile(text) to anon, authenticated;
grant execute on function public.ruhh_pull(uuid, text) to anon, authenticated;
grant execute on function public.ruhh_push(uuid, text, jsonb) to anon, authenticated;
