-- Sensitive agent actions (edits/deletes) become proposals that need an exact,
-- single-use, expiring approval. Execution only enqueues into ruhh_agent_inbox.
--
-- Approval authority: ONLY the user's own app session (ruhh_sessions token, obtained by
-- PIN login on the phone) can approve, via ruhh_proposal_decide_v2. The agent (service
-- role inside ruhh-agent) can create, list (without params_hash) and reject proposals,
-- but has no EXECUTE on the approve path at all.

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

-- Agent-side reject (service role). Rejecting is always safe; it can never execute.
create or replace function public.ruhh_agent_proposal_reject(p_user_id uuid, p_proposal_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  return public.ruhh_agent_proposal_decide(p_user_id, p_proposal_id, 'reject', null);
end;
$$;

-- Readable description of the proposal target for the approval screen (cloud copy).
create or replace function public.ruhh_agent_target_describe(p_user uuid, p_action text, p_target uuid)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select case
    when p_action in ('tx.edit', 'tx.delete') then (
      select jsonb_build_object('kind', 'transaction', 'amount', t.amount, 'is_income', t.is_income,
        'category', t.category, 'title', t.title, 'note', left(t.note, 120), 'occurred_at', t.occurred_at)
      from public.transactions t where t.id = p_target and t.user_id = p_user)
    when p_action = 'movie.delete' then (
      select jsonb_build_object('kind', 'movie', 'title', m.title, 'media_type', m.media_type)
      from public.movies m where m.id = p_target and m.user_id = p_user)
    else null end;
$$;

-- App (user session): pending, unexpired proposals of the session's own user.
create or replace function public.ruhh_proposals_list_v2(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := public.ruhh_session_user(p_token);
begin
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'id', p.id, 'action', p.action, 'summary', p.summary, 'params', p.params,
      'params_hash', p.params_hash, 'target_id', p.target,
      'target', public.ruhh_agent_target_describe(p.user_id, p.action, p.target),
      'created_at', p.created_at, 'expires_at', p.expires_at) order by p.created_at desc)
    from public.ruhh_agent_proposals p
    where p.user_id = v_user and p.status = 'pending' and p.expires_at > now()
  ), '[]'::jsonb);
end;
$$;

-- App (user session): approve or reject. All checks (owner, pending, expiry, exact hash,
-- target state, single use under row lock) are in ruhh_agent_proposal_decide.
create or replace function public.ruhh_proposal_decide_v2(
  p_token text,
  p_proposal_id uuid,
  p_params_hash text,
  p_decision text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := public.ruhh_session_user(p_token);
begin
  if p_decision is null or p_decision not in ('approve', 'reject') then
    raise exception 'proposal_bad_decision' using errcode = '22023';
  end if;
  return public.ruhh_agent_proposal_decide(v_user, p_proposal_id, p_decision, p_params_hash);
end;
$$;

revoke all on function public.ruhh_agent_params_hash(text, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.ruhh_agent_target_exists(uuid, text, uuid) from public, anon, authenticated;
revoke all on function public.ruhh_agent_target_describe(uuid, text, uuid) from public, anon, authenticated;
revoke all on function public.ruhh_agent_proposal_create(uuid, uuid, text, uuid, jsonb, text) from public, anon, authenticated;
-- decide is internal: no API role (including service_role, i.e. the agent) may call it.
revoke all on function public.ruhh_agent_proposal_decide(uuid, uuid, text, text) from public, anon, authenticated, service_role;
revoke all on function public.ruhh_agent_proposal_reject(uuid, uuid) from public, anon, authenticated;
grant execute on function public.ruhh_agent_proposal_create(uuid, uuid, text, uuid, jsonb, text) to service_role;
grant execute on function public.ruhh_agent_proposal_reject(uuid, uuid) to service_role;

-- service_role (the agent's runtime) is explicitly excluded from the user-session API.
revoke all on function public.ruhh_proposals_list_v2(text) from public, service_role;
revoke all on function public.ruhh_proposal_decide_v2(text, uuid, text, text) from public, service_role;
grant execute on function public.ruhh_proposals_list_v2(text) to anon, authenticated;
grant execute on function public.ruhh_proposal_decide_v2(text, uuid, text, text) to anon, authenticated;
