-- Sensitive agent actions (edits/deletes) become proposals that need an exact,
-- single-use, expiring approval. Execution only enqueues into ruhh_agent_inbox.

create table if not exists public.ruhh_agent_proposals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  credential_id uuid references public.ruhh_agent_credentials(id) on delete set null,
  action text not null check (action in ('tx.edit', 'tx.delete', 'movie.delete')),
  target uuid not null,
  params jsonb not null check (jsonb_typeof(params) = 'object' and octet_length(params::text) <= 2048),
  params_hash text not null check (params_hash ~ '^[0-9a-f]{64}$'),
  summary text not null check (char_length(summary) <= 200),
  status text not null default 'pending' check (status in ('pending', 'executed', 'rejected')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '15 minutes',
  decided_at timestamptz,
  executed_at timestamptz,
  inbox_id uuid references public.ruhh_agent_inbox(id) on delete set null
);
create index if not exists ruhh_agent_proposals_user_idx on public.ruhh_agent_proposals (user_id, status, expires_at);

alter table public.ruhh_agent_proposals enable row level security;
revoke all on public.ruhh_agent_proposals from public, anon, authenticated;

create or replace function public.ruhh_agent_params_hash(p_action text, p_target uuid, p_params jsonb)
returns text
language sql
immutable
set search_path = public, extensions
as $$
  -- jsonb text form is canonical (sorted keys, normalised whitespace)
  select encode(extensions.digest(convert_to(
    jsonb_build_object('action', p_action, 'target', p_target, 'params', p_params)::text, 'UTF8'), 'sha256'), 'hex');
$$;

create or replace function public.ruhh_agent_target_exists(p_user uuid, p_action text, p_target uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select case
    when p_action in ('tx.edit', 'tx.delete') then
      exists (select 1 from public.transactions where id = p_target and user_id = p_user)
    when p_action = 'movie.delete' then
      exists (select 1 from public.movies where id = p_target and user_id = p_user)
    else false end;
$$;

create or replace function public.ruhh_agent_proposal_create(
  p_user_id uuid,
  p_credential_id uuid,
  p_action text,
  p_target uuid,
  p_params jsonb,
  p_summary text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_row public.ruhh_agent_proposals%rowtype;
begin
  if not public.ruhh_agent_target_exists(p_user_id, p_action, p_target) then
    raise exception 'target_not_found';
  end if;
  if (select count(*) from public.ruhh_agent_proposals
      where user_id = p_user_id and status = 'pending' and expires_at > now()) >= 20 then
    raise exception 'proposal_limit';
  end if;
  insert into public.ruhh_agent_proposals (user_id, credential_id, action, target, params, params_hash, summary)
  values (p_user_id, p_credential_id, p_action, p_target, p_params,
          public.ruhh_agent_params_hash(p_action, p_target, p_params), left(p_summary, 200))
  returning * into v_row;
  return jsonb_build_object('proposal_id', v_row.id, 'params_hash', v_row.params_hash,
    'summary', v_row.summary, 'expires_at', v_row.expires_at, 'status', v_row.status);
end;
$$;

-- Approve (exact id + params_hash, single use, not expired, target re-validated) or reject.
create or replace function public.ruhh_agent_proposal_decide(
  p_user_id uuid,
  p_proposal_id uuid,
  p_decision text,
  p_params_hash text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_p public.ruhh_agent_proposals%rowtype;
  v_entity text;
  v_op text;
  v_payload jsonb;
  v_inbox jsonb;
begin
  select * into v_p from public.ruhh_agent_proposals
  where id = p_proposal_id and user_id = p_user_id
  for update;
  if not found then
    raise exception 'proposal_not_found';
  end if;
  if v_p.status <> 'pending' then
    raise exception 'proposal_already_decided';
  end if;
  if v_p.expires_at <= now() then
    raise exception 'proposal_expired';
  end if;

  if p_decision = 'reject' then
    update public.ruhh_agent_proposals set status = 'rejected', decided_at = now() where id = v_p.id;
    return jsonb_build_object('proposal_id', v_p.id, 'status', 'rejected');
  end if;
  if p_decision <> 'approve' then
    raise exception 'proposal_bad_decision';
  end if;

  if p_params_hash is null or p_params_hash <> v_p.params_hash
     or public.ruhh_agent_params_hash(v_p.action, v_p.target, v_p.params) <> v_p.params_hash then
    raise exception 'proposal_hash_mismatch';
  end if;
  if not public.ruhh_agent_target_exists(p_user_id, v_p.action, v_p.target) then
    raise exception 'target_not_found';
  end if;

  v_entity := case when v_p.action like 'tx.%' then 'transaction' else 'movie' end;
  v_op := case when v_p.action like '%.delete' then 'delete' else 'update' end;
  v_payload := v_p.params || jsonb_build_object('id', v_p.target);
  v_inbox := public.ruhh_inbox_enqueue(p_user_id, v_entity, v_op, v_payload, 'proposal:' || v_p.id::text, 'agent-approved');

  update public.ruhh_agent_proposals
  set status = 'executed', decided_at = now(), executed_at = now(), inbox_id = (v_inbox->>'id')::uuid
  where id = v_p.id;
  return jsonb_build_object('proposal_id', v_p.id, 'status', 'executed', 'inbox_id', v_inbox->>'id');
end;
$$;

revoke all on function public.ruhh_agent_params_hash(text, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.ruhh_agent_target_exists(uuid, text, uuid) from public, anon, authenticated;
revoke all on function public.ruhh_agent_proposal_create(uuid, uuid, text, uuid, jsonb, text) from public, anon, authenticated;
revoke all on function public.ruhh_agent_proposal_decide(uuid, uuid, text, text) from public, anon, authenticated;
grant execute on function public.ruhh_agent_proposal_create(uuid, uuid, text, uuid, jsonb, text) to service_role;
grant execute on function public.ruhh_agent_proposal_decide(uuid, uuid, text, text) to service_role;
