-- Agent inbox (additive). External writes (Telegram/agent) are NEVER written to the synced
-- tables directly, because ruhh_push reconciles the cloud to the phone's full snapshot and
-- would delete them. Instead they queue here; the app applies them into Isar through its
-- repositories BEFORE its next snapshot push, then acknowledges.

create table if not exists public.ruhh_agent_inbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  entity text not null check (entity in ('transaction', 'habit_completion', 'prayer_log', 'movie')),
  op text not null check (op in ('create', 'upsert', 'update', 'delete')),
  payload jsonb not null check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 4096),
  status text not null default 'pending' check (status in ('pending', 'applied', 'failed', 'rejected')),
  idempotency_key text not null check (char_length(idempotency_key) between 8 and 128),
  source text not null default 'agent' check (char_length(source) <= 32),
  attempts int not null default 0,
  error text check (error is null or char_length(error) <= 64),
  created_at timestamptz not null default now(),
  applied_at timestamptz,
  unique (user_id, idempotency_key)
);
create index if not exists ruhh_agent_inbox_pending_idx
  on public.ruhh_agent_inbox (user_id, created_at) where status = 'pending';

alter table public.ruhh_agent_inbox enable row level security;
revoke all on public.ruhh_agent_inbox from public, anon, authenticated;

-- Server-side enqueue used by the ruhh-agent Edge Function (service role only).
-- Idempotent on (user_id, idempotency_key): replays return the existing row.
create or replace function public.ruhh_inbox_enqueue(
  p_user_id uuid,
  p_entity text,
  p_op text,
  p_payload jsonb,
  p_idempotency_key text,
  p_source text default 'agent'
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_row public.ruhh_agent_inbox%rowtype;
  v_pending int;
begin
  select * into v_row from public.ruhh_agent_inbox
  where user_id = p_user_id and idempotency_key = p_idempotency_key;
  if found then
    return jsonb_build_object('id', v_row.id, 'status', v_row.status, 'duplicate', true);
  end if;

  select count(*) into v_pending from public.ruhh_agent_inbox
  where user_id = p_user_id and status = 'pending';
  if v_pending >= 200 then
    raise exception 'inbox_full' using errcode = '54000';
  end if;

  insert into public.ruhh_agent_inbox (user_id, entity, op, payload, idempotency_key, source)
  values (p_user_id, p_entity, p_op, p_payload, p_idempotency_key, coalesce(p_source, 'agent'))
  on conflict (user_id, idempotency_key) do nothing
  returning * into v_row;
  if v_row.id is null then
    select * into v_row from public.ruhh_agent_inbox
    where user_id = p_user_id and idempotency_key = p_idempotency_key;
    return jsonb_build_object('id', v_row.id, 'status', v_row.status, 'duplicate', true);
  end if;
  return jsonb_build_object('id', v_row.id, 'status', v_row.status, 'duplicate', false);
end;
$$;

-- App: fetch pending actions for the session's user (oldest first, bounded).
create or replace function public.ruhh_inbox_fetch_v2(p_token text, p_limit int default 50)
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
      'id', i.id, 'entity', i.entity, 'op', i.op, 'payload', i.payload,
      'attempts', i.attempts, 'created_at', i.created_at) order by i.created_at, i.id)
    from (
      select * from public.ruhh_agent_inbox
      where user_id = v_user and status = 'pending'
      order by created_at, id
      limit greatest(1, least(coalesce(p_limit, 50), 100))
    ) i
  ), '[]'::jsonb);
end;
$$;

-- App: acknowledge results. Only touches the caller's own pending rows (idempotent).
-- p_results: [{"id": uuid, "status": "applied"|"failed"|"rejected", "error": short code}]
-- Each item is validated on its own; a bad item never aborts the batch. Returns one result per
-- input item: {"id", "result": "updated"|"not_pending"|"invalid_id"|"invalid_status"}.
create or replace function public.ruhh_inbox_ack_v2(p_token text, p_results jsonb)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_user uuid := public.ruhh_session_user(p_token);
  r jsonb;
  v_count int;
  v_status text;
  v_id text;
  v_out jsonb := '[]'::jsonb;
begin
  if p_results is null or jsonb_typeof(p_results) <> 'array' or jsonb_array_length(p_results) > 100 then
    raise exception 'invalid_results' using errcode = '22023';
  end if;
  for r in select * from jsonb_array_elements(p_results) loop
    v_id := case when jsonb_typeof(r) = 'object' then r->>'id' else null end;
    if v_id is null
       or v_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      v_out := v_out || jsonb_build_array(jsonb_build_object('id', left(v_id, 40), 'result', 'invalid_id'));
      continue;
    end if;
    v_status := r->>'status';
    if v_status is null or v_status not in ('applied', 'failed', 'rejected') then
      v_out := v_out || jsonb_build_array(jsonb_build_object('id', v_id, 'result', 'invalid_status'));
      continue;
    end if;
    update public.ruhh_agent_inbox i
    set attempts = i.attempts + 1,
        status = case
          when v_status = 'applied' then 'applied'
          when v_status = 'rejected' then 'rejected'
          when i.attempts + 1 >= 5 then 'failed'
          else 'pending' end,
        applied_at = case when v_status = 'applied' then now() else i.applied_at end,
        error = case when v_status = 'applied' then null else left(r->>'error', 64) end
    where i.id = v_id::uuid and i.user_id = v_user and i.status = 'pending';
    get diagnostics v_count = row_count;
    v_out := v_out || jsonb_build_array(jsonb_build_object('id', v_id,
      'result', case when v_count > 0 then 'updated' else 'not_pending' end));
  end loop;
  return v_out;
end;
$$;

revoke all on function public.ruhh_inbox_enqueue(uuid, text, text, jsonb, text, text) from public, anon, authenticated;
grant execute on function public.ruhh_inbox_enqueue(uuid, text, text, jsonb, text, text) to service_role;
revoke all on function public.ruhh_inbox_fetch_v2(text, int) from public;
revoke all on function public.ruhh_inbox_ack_v2(text, jsonb) from public;
grant execute on function public.ruhh_inbox_fetch_v2(text, int) to anon, authenticated;
grant execute on function public.ruhh_inbox_ack_v2(text, jsonb) to anon, authenticated;
