begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(16);

select ok(not has_table_privilege('anon', 'public.ruhh_agent_inbox', 'SELECT,INSERT,UPDATE,DELETE'), 'anon has no direct inbox access');
select ok(not has_function_privilege('anon', 'public.ruhh_inbox_enqueue(uuid,text,text,jsonb,text,text)', 'EXECUTE'), 'anon cannot enqueue');
select ok(has_function_privilege('service_role', 'public.ruhh_inbox_enqueue(uuid,text,text,jsonb,text,text)', 'EXECUTE'), 'service_role can enqueue');

select public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000a1', 'inbox_alice', '123456', '1.0.31');
select public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000b1', 'inbox_bob', '123456', '1.0.31');
create temp table tk as select
  (public.ruhh_login('inbox_alice', '123456', '1.0.31'))->>'token' as a,
  (public.ruhh_login('inbox_bob', '123456', '1.0.31'))->>'token' as b;

create temp table e1 as select public.ruhh_inbox_enqueue('00000000-0000-4000-8000-0000000000a1', 'transaction', 'create',
  '{"amount": 12.5, "is_income": false, "category": "Food", "occurred_at": "2026-10-20T10:00:00Z"}', 'req-0001-abc') as r;
select is((select r->>'duplicate' from e1), 'false', 'first enqueue creates row');
select is((public.ruhh_inbox_enqueue('00000000-0000-4000-8000-0000000000a1', 'transaction', 'create',
  '{"amount": 99}', 'req-0001-abc'))->>'id', (select r->>'id' from e1), 'replayed idempotency key returns same row');
select is((select count(*)::int from ruhh_agent_inbox where user_id = '00000000-0000-4000-8000-0000000000a1'), 1, 'no duplicate row');
select throws_ok($q$select public.ruhh_inbox_enqueue('00000000-0000-4000-8000-0000000000a1', 'wallet', 'create', '{}', 'req-0002-abc')$q$,
  '23514', null, 'local-only entity (wallet) rejected by check constraint');

select is(jsonb_array_length(public.ruhh_inbox_fetch_v2((select a from tk))), 1, 'owner fetches pending action');
select is(jsonb_array_length(public.ruhh_inbox_fetch_v2((select b from tk))), 0, 'other user sees nothing');
select is(public.ruhh_inbox_ack_v2((select b from tk), jsonb_build_array(jsonb_build_object('id', (select r->>'id' from e1), 'status', 'applied'))),
  0, 'other user cannot ack someone else''s action');

-- failed ack keeps it pending (retry) until 5 attempts
select public.ruhh_inbox_ack_v2((select a from tk), jsonb_build_array(jsonb_build_object('id', (select r->>'id' from e1), 'status', 'failed', 'error', 'io_error')));
select is((select status from ruhh_agent_inbox where id = (select (r->>'id')::uuid from e1)), 'pending', 'failed attempt stays pending for retry');
select is(public.ruhh_inbox_ack_v2((select a from tk), jsonb_build_array(jsonb_build_object('id', (select r->>'id' from e1), 'status', 'applied'))),
  1, 'owner acks applied');
select is(public.ruhh_inbox_ack_v2((select a from tk), jsonb_build_array(jsonb_build_object('id', (select r->>'id' from e1), 'status', 'applied'))),
  0, 'second ack is a no-op (idempotent)');
select is(jsonb_array_length(public.ruhh_inbox_fetch_v2((select a from tk))), 0, 'applied action no longer fetched');

create temp table e2 as select public.ruhh_inbox_enqueue('00000000-0000-4000-8000-0000000000a1', 'movie', 'create', '{"title":"X"}', 'req-0003-abc') as r;
select public.ruhh_inbox_ack_v2((select a from tk), jsonb_build_array(jsonb_build_object('id', (select r->>'id' from e2), 'status', 'failed', 'error', 'e'))) from generate_series(1, 5);
select is((select status from ruhh_agent_inbox where id = (select (r->>'id')::uuid from e2)), 'failed', 'gives up after 5 failed attempts');
select throws_ok($q$select public.ruhh_inbox_fetch_v2('garbage')$q$, '28000', 'session_invalid', 'fetch requires a valid session');

select * from finish();
rollback;
