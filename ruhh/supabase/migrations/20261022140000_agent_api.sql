-- ruhh-agent API support (additive). Service role only; nothing granted to anon/authenticated.

create table if not exists public.ruhh_agent_credentials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  label text not null default 'agent' check (char_length(label) <= 64),
  -- No 'approve' scope exists: an agent credential can never approve a proposal.
  -- Approval requires the user's own app session (ruhh_proposal_decide_v2).
  scopes text[] not null default array['read']
    check (scopes <@ array['read', 'write']::text[] and cardinality(scopes) > 0),
  created_at timestamptz not null default now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  last_used_at timestamptz
);
create index if not exists ruhh_agent_credentials_user_idx on public.ruhh_agent_credentials (user_id);

-- Metadata-only audit: never params, amounts, titles or notes.
create table if not exists public.ruhh_agent_audit (
  id bigint generated always as identity primary key,
  credential_id uuid references public.ruhh_agent_credentials(id) on delete set null,
  user_id uuid references public.users(id) on delete cascade,
  request_id text check (char_length(request_id) <= 64),
  op text check (char_length(op) <= 48),
  outcome text not null check (outcome in ('ok', 'error', 'denied', 'rate_limited', 'replay')),
  error_code text check (char_length(error_code) <= 48),
  duration_ms int,
  created_at timestamptz not null default now()
);
create index if not exists ruhh_agent_audit_cred_idx on public.ruhh_agent_audit (credential_id, created_at desc);

-- Idempotency for write operations: same request_id => same response, applied once.
create table if not exists public.ruhh_agent_requests (
  credential_id uuid not null references public.ruhh_agent_credentials(id) on delete cascade,
  request_id text not null check (char_length(request_id) between 8 and 64),
  op text not null,
  -- sha256(op + canonical params): a reused request_id with different op/params is refused (409)
  params_hash text check (params_hash is null or params_hash ~ '^[0-9a-f]{64}$'),
  response jsonb not null,
  created_at timestamptz not null default now(),
  primary key (credential_id, request_id)
);

alter table public.ruhh_agent_credentials enable row level security;
alter table public.ruhh_agent_audit enable row level security;
alter table public.ruhh_agent_requests enable row level security;
revoke all on public.ruhh_agent_credentials from public, anon, authenticated;
revoke all on public.ruhh_agent_audit from public, anon, authenticated;
revoke all on public.ruhh_agent_requests from public, anon, authenticated;

-- Mint a credential (run by the project owner in the SQL editor / psql only).
-- Returns the raw token ONCE; only its SHA-256 is stored.
create or replace function public.ruhh_agent_credential_create(
  p_user_id uuid,
  p_label text default 'grok-bot',
  p_scopes text[] default array['read'],
  p_valid_days int default 90
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, extensions
as $$
declare
  v_token text := 'ruhh_agent_' || encode(extensions.gen_random_bytes(32), 'hex');
  v_id uuid;
begin
  if not exists (select 1 from public.users where id = p_user_id) then
    raise exception 'unknown_user';
  end if;
  insert into public.ruhh_agent_credentials (user_id, token_hash, label, scopes, expires_at)
  values (p_user_id, public.ruhh_token_hash(v_token), p_label, p_scopes,
          case when p_valid_days is null then null else now() + make_interval(days => p_valid_days) end)
  returning id into v_id;
  return jsonb_build_object('credential_id', v_id, 'token', v_token);
end;
$$;

create or replace function public.ruhh_agent_credential_revoke(p_credential_id uuid)
returns boolean
language sql
volatile
security definer
set search_path = public
as $$
  update public.ruhh_agent_credentials set revoked_at = now()
  where id = p_credential_id and revoked_at is null
  returning true;
$$;

revoke all on function public.ruhh_agent_credential_create(uuid, text, text[], int) from public, anon, authenticated, service_role;
revoke all on function public.ruhh_agent_credential_revoke(uuid) from public, anon, authenticated;
grant execute on function public.ruhh_agent_credential_revoke(uuid) to service_role;
