begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(15);

select ok(not has_table_privilege('anon', 'public.ruhh_agent_proposals', 'SELECT,INSERT,UPDATE,DELETE'), 'anon has no proposal access');
select ok(not has_function_privilege('anon', 'public.ruhh_agent_proposal_decide(uuid,uuid,text,text)', 'EXECUTE'), 'anon cannot approve');

select public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000d1', 'prop_dan', '123456', '1.0.31');
select public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000e1', 'prop_eve', '123456', '1.0.31');
insert into transactions (id, user_id, amount, category, occurred_at)
values ('30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-0000000000d1', 10, 'Food', now());

select throws_ok($q$select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000e1', null, 'tx.delete',
  '30000000-0000-4000-8000-000000000001', '{}', 'x')$q$, 'P0001', 'target_not_found', 'cannot propose on another user''s row');

create temp table p as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000d1', null, 'tx.edit',
  '30000000-0000-4000-8000-000000000001', '{"amount": 12}', 'Change amount to 12') as r;
select is((select r->>'status' from p), 'pending', 'proposal created pending');
select is((select r->>'params_hash' from p),
  ruhh_agent_params_hash('tx.edit', '30000000-0000-4000-8000-000000000001', '{"amount": 12}'), 'hash binds action+target+params');

select throws_ok(format($q$select public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000e1', %L, 'approve', %L)$q$,
  (select r->>'proposal_id' from p), (select r->>'params_hash' from p)), 'P0001', 'proposal_not_found', 'other user cannot approve');
select throws_ok(format($q$select public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000d1', %L, 'approve', %L)$q$,
  (select r->>'proposal_id' from p), repeat('0', 64)), 'P0001', 'proposal_hash_mismatch', 'altered/wrong hash rejected');
update ruhh_agent_proposals set params = '{"amount": 9999}' where id = (select (r->>'proposal_id')::uuid from p);
select throws_ok(format($q$select public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000d1', %L, 'approve', %L)$q$,
  (select r->>'proposal_id' from p), (select r->>'params_hash' from p)), 'P0001', 'proposal_hash_mismatch', 'tampered stored params rejected');
update ruhh_agent_proposals set params = '{"amount": 12}' where id = (select (r->>'proposal_id')::uuid from p);

create temp table d as select public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000d1',
  (select (r->>'proposal_id')::uuid from p), 'approve', (select r->>'params_hash' from p)) as r;
select is((select r->>'status' from d), 'executed', 'exact approval executes');
select is((select entity || '/' || op || '/' || (payload->>'amount') from ruhh_agent_inbox where id = (select (r->>'inbox_id')::uuid from d)),
  'transaction/update/12', 'execution only enqueues an inbox update');
select throws_ok(format($q$select public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000d1', %L, 'approve', %L)$q$,
  (select r->>'proposal_id' from p), (select r->>'params_hash' from p)), 'P0001', 'proposal_already_decided', 'approval is single use');

-- expiry
create temp table p2 as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000d1', null, 'tx.delete',
  '30000000-0000-4000-8000-000000000001', '{}', 'Delete') as r;
update ruhh_agent_proposals set expires_at = now() - interval '1 second' where id = (select (r->>'proposal_id')::uuid from p2);
select throws_ok(format($q$select public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000d1', %L, 'approve', %L)$q$,
  (select r->>'proposal_id' from p2), (select r->>'params_hash' from p2)), 'P0001', 'proposal_expired', 'expired proposal rejected');

-- target revalidation at approval time
create temp table p3 as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000d1', null, 'tx.delete',
  '30000000-0000-4000-8000-000000000001', '{}', 'Delete') as r;
delete from transactions where id = '30000000-0000-4000-8000-000000000001';
select throws_ok(format($q$select public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000d1', %L, 'approve', %L)$q$,
  (select r->>'proposal_id' from p3), (select r->>'params_hash' from p3)), 'P0001', 'target_not_found', 'target re-validated on approval');

select is((public.ruhh_agent_proposal_decide('00000000-0000-4000-8000-0000000000d1',
  (select (r->>'proposal_id')::uuid from p3), 'reject'))->>'status', 'rejected', 'reject works without hash');
select is((select count(*)::int from ruhh_agent_inbox where user_id = '00000000-0000-4000-8000-0000000000d1'), 1,
  'only the one approved action reached the inbox');

select * from finish();
rollback;
