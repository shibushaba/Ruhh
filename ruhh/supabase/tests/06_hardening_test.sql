-- Username rules, per-item inbox acks, edit precondition, replay hash column, cleanup.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(19);

-- username validation
select is((public.ruhh_login(repeat('x', 65), '123456', '1.0.31'))->>'error', 'invalid_credentials', 'login: >64 chars refused');
select is((public.ruhh_login('ab', '123456', '1.0.31'))->>'error', 'invalid_credentials', 'login: <3 chars refused');
select is((select count(*)::int from ruhh_login_attempts where username_key in (repeat('x', 65), 'ab')), 0,
  'invalid names do not grow ruhh_login_attempts');
select is((public.ruhh_register_user_v2(gen_random_uuid(), repeat('y', 65), '123456', '1.0.31'))->>'error', 'username_invalid', 'register: >64 refused');
select is((public.ruhh_register_user_v2(gen_random_uuid(), E'bad\tname', '123456', '1.0.31'))->>'error', 'username_invalid', 'register: control chars refused');
-- legacy long username created by the old app still logs in
select public.ruhh_register_user('00000000-0000-4000-8000-0000000000c9', repeat('z', 70),
  encode(digest(convert_to('s:123456', 'UTF8'), 'sha256'), 'hex'), 's');
select is((public.ruhh_login(repeat('z', 70), '123456', '1.0.31'))->>'ok', 'true', 'legacy >64 username still works');

-- per-item ack
create temp table u as select public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000c1', 'hard_cat', '123456', '1.0.31') as r;
create temp table e as select public.ruhh_inbox_enqueue('00000000-0000-4000-8000-0000000000c1', 'transaction', 'create', '{"amount":1}', 'hard-key-0001') as r;
create temp table a as select public.ruhh_inbox_ack_v2((select r->>'token' from u), jsonb_build_array(
  jsonb_build_object('id', repeat('-', 36), 'status', 'applied'),
  jsonb_build_object('id', 'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz', 'status', 'applied'),
  jsonb_build_object('id', (select r->>'id' from e), 'status', 'bogus'),
  '"not-an-object"'::jsonb,
  jsonb_build_object('id', (select r->>'id' from e), 'status', 'applied'),
  jsonb_build_object('id', (select r->>'id' from e), 'status', 'applied'))) as r;
select is(jsonb_array_length((select r from a)), 6, 'one result per item, batch not aborted');
select is((select r->0->>'result' from a), 'invalid_id', 'dashes-only id rejected per item');
select is((select r->1->>'result' from a), 'invalid_id', 'non-hex id rejected per item');
select is((select r->2->>'result' from a), 'invalid_status', 'bad status rejected per item');
select is((select r->4->>'result' from a), 'updated', 'valid item applied');
select is((select r->5->>'result' from a), 'not_pending', 'second ack is a no-op');

-- tx.edit precondition
insert into transactions (id, user_id, amount, category, title, note, occurred_at)
values ('30000000-0000-4000-8000-0000000000c1', '00000000-0000-4000-8000-0000000000c1', 10, 'Food', 'Tea', '', now());
create temp table p as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000c1', null, 'tx.edit',
  '30000000-0000-4000-8000-0000000000c1',
  '{"amount": 12, "expected": {"amount": 10, "category": "Food", "title": "Tea", "note": ""}}', 'Edit') as r;
update transactions set amount = 11 where id = '30000000-0000-4000-8000-0000000000c1';
create temp table d as select public.ruhh_proposal_decide_v2((select r->>'token' from u),
  (select (r->>'proposal_id')::uuid from p), (select r->>'params_hash' from p), 'approve') as r;
select is((select r->>'reason' from d), 'conflict', 'stale edit -> conflict');
select is((select status from ruhh_agent_proposals where id = (select (r->>'proposal_id')::uuid from p)), 'rejected',
  'stale proposal is rejected (committed)');
select is((select count(*)::int from ruhh_agent_inbox where idempotency_key like 'proposal:%'
  and user_id = '00000000-0000-4000-8000-0000000000c1'), 0, 'nothing enqueued for a stale edit');
create temp table p2 as select public.ruhh_agent_proposal_create('00000000-0000-4000-8000-0000000000c1', null, 'tx.edit',
  '30000000-0000-4000-8000-0000000000c1',
  '{"amount": 12, "expected": {"amount": 11, "category": "Food", "title": "Tea", "note": ""}}', 'Edit') as r;
select is((public.ruhh_proposal_decide_v2((select r->>'token' from u), (select (r->>'proposal_id')::uuid from p2),
  (select r->>'params_hash' from p2), 'approve'))->>'status', 'executed', 'unchanged edit executes');

-- replay hash column + cleanup
select has_column('public', 'ruhh_agent_requests', 'params_hash', 'replay rows store the op+params hash');
insert into ruhh_login_attempts (username_key, success, created_at) values ('old_one', false, now() - interval '40 days');
select ok((public.ruhh_security_cleanup()->>'login_attempts')::int >= 1, 'cleanup removes old login attempts');
select ok(not has_function_privilege('anon', 'public.ruhh_security_cleanup()', 'EXECUTE'), 'cleanup not callable by anon');

select * from finish();
rollback;
