-- Approval authority: only the user's own app session may approve; the agent never can.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(20);

-- grants: the agent's role (service_role) has no path to approve
select ok(not has_function_privilege('service_role', 'public.ruhh_agent_proposal_decide(uuid,uuid,text,text)', 'EXECUTE'),
  'service_role (agent) cannot execute decide');
select ok(has_function_privilege('service_role', 'public.ruhh_agent_proposal_reject(uuid,uuid)', 'EXECUTE'),
  'service_role can reject');
select ok(not has_function_privilege('anon', 'public.ruhh_agent_proposal_reject(uuid,uuid)', 'EXECUTE'), 'anon cannot use agent reject');
select ok(not has_function_privilege('anon', 'public.ruhh_agent_target_describe(uuid,text,uuid)', 'EXECUTE'), 'describe is internal');
select ok(has_function_privilege('anon', 'public.ruhh_proposal_decide_v2(text,uuid,text,text)', 'EXECUTE'), 'app decide_v2 callable (session-gated)');

create temp table u as select
  public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000f1', 'appr_fay', '123456', '1.0.31') as fay,
  public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000f2', 'appr_gus', '123456', '1.0.31') as gus;
insert into transactions (id, user_id, amount, category, occurred_at)
values ('30000000-0000-4000-8000-0000000000f1', '00000000-0000-4000-8000-0000000000f1', 10, 'Food', now());

select throws_ok($q$select public.ruhh_agent_credential_create('00000000-0000-4000-8000-0000000000f1', 'x', array['read','approve'], 1)$q$,
  '23514', null, 'an approve scope can no longer be minted');

create temp table p as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000f1', null, 'tx.delete',
  '30000000-0000-4000-8000-0000000000f1', '{}', 'Delete one transaction') as r;

-- agent role: every approve path is denied (privileges checked above/below; a session-gated
-- call with an agent token fails as well)
select ok(not has_function_privilege('service_role', 'public.ruhh_proposal_decide_v2(text,uuid,text,text)', 'EXECUTE'),
  'service_role (agent) cannot call decide_v2 either');
select throws_ok(format($q$select public.ruhh_proposal_decide_v2(%L, %L, %L, 'approve')$q$,
  'ruhh_agent_' || repeat('a', 64), (select r->>'proposal_id' from p), (select r->>'params_hash' from p)),
  '28000', 'session_invalid', 'agent token is not a user session');

-- user sessions
select throws_ok($q$select public.ruhh_proposals_list_v2('nope')$q$, '28000', 'session_invalid', 'list needs a session');
select is(jsonb_array_length(public.ruhh_proposals_list_v2((select fay->>'token' from u))), 1, 'owner sees the pending proposal');
select is(public.ruhh_proposals_list_v2((select fay->>'token' from u))->0->'target'->>'category', 'Food', 'readable target shown');
select is(jsonb_array_length(public.ruhh_proposals_list_v2((select gus->>'token' from u))), 0, 'other user sees nothing');
select throws_ok(format($q$select public.ruhh_proposal_decide_v2(%L, %L, %L, 'approve')$q$,
  (select gus->>'token' from u), (select r->>'proposal_id' from p), (select r->>'params_hash' from p)),
  'P0001', 'proposal_not_found', 'other user''s session cannot approve');
select throws_ok(format($q$select public.ruhh_proposal_decide_v2(%L, %L, %L, 'approve')$q$,
  (select fay->>'token' from u), (select r->>'proposal_id' from p), repeat('0', 64)),
  'P0001', 'proposal_hash_mismatch', 'altered hash rejected');
select is((public.ruhh_proposal_decide_v2((select fay->>'token' from u), (select (r->>'proposal_id')::uuid from p),
  (select r->>'params_hash' from p), 'approve'))->>'status', 'executed', 'owner session approves');
select throws_ok(format($q$select public.ruhh_proposal_decide_v2(%L, %L, %L, 'approve')$q$,
  (select fay->>'token' from u), (select r->>'proposal_id' from p), (select r->>'params_hash' from p)),
  'P0001', 'proposal_already_decided', 'replayed approval rejected');

-- expired
create temp table p2 as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000f1', null, 'tx.delete',
  '30000000-0000-4000-8000-0000000000f1', '{}', 'Delete one transaction') as r;
update ruhh_agent_proposals set expires_at = now() - interval '1 second' where id = (select (r->>'proposal_id')::uuid from p2);
select throws_ok(format($q$select public.ruhh_proposal_decide_v2(%L, %L, %L, 'approve')$q$,
  (select fay->>'token' from u), (select r->>'proposal_id' from p2), (select r->>'params_hash' from p2)),
  'P0001', 'proposal_expired', 'expired proposal rejected');

-- revoked session cannot approve
create temp table p3 as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000f1', null, 'tx.delete',
  '30000000-0000-4000-8000-0000000000f1', '{}', 'Delete one transaction') as r;
select public.ruhh_logout((select fay->>'token' from u));
select throws_ok(format($q$select public.ruhh_proposal_decide_v2(%L, %L, %L, 'approve')$q$,
  (select fay->>'token' from u), (select r->>'proposal_id' from p3), (select r->>'params_hash' from p3)),
  '28000', 'session_invalid', 'revoked session cannot approve');

-- agent reject works and is final
select is((public.ruhh_agent_proposal_reject('00000000-0000-4000-8000-0000000000f1', (select (r->>'proposal_id')::uuid from p3)))->>'status',
  'rejected', 'agent can reject');
select is((select count(*)::int from ruhh_agent_inbox where user_id = '00000000-0000-4000-8000-0000000000f1'), 1,
  'only the user-approved action reached the inbox');

select * from finish();
rollback;
