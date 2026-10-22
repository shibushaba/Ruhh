begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(10);

select ok(not has_table_privilege('anon', 'public.' || t, 'SELECT,INSERT,UPDATE,DELETE'), 'anon has no access to ' || t)
from unnest(array['ruhh_agent_credentials', 'ruhh_agent_audit', 'ruhh_agent_requests']) t;
select ok(not has_function_privilege('anon', 'public.ruhh_agent_credential_create(uuid,text,text[],int)', 'EXECUTE'), 'anon cannot mint credentials');
select ok(not has_function_privilege('service_role', 'public.ruhh_agent_credential_create(uuid,text,text[],int)', 'EXECUTE'), 'service_role (edge function) cannot mint credentials');

select public.ruhh_register_user_v2('00000000-0000-4000-8000-0000000000c1', 'agent_carol', '123456', '1.0.31');
create temp table c as select public.ruhh_agent_credential_create('00000000-0000-4000-8000-0000000000c1', 'test', array['read']) as r;
select ok((select r->>'token' ~ '^ruhh_agent_[0-9a-f]{64}$' from c), 'token format');
select is((select count(*)::int from ruhh_agent_credentials where token_hash = (select r->>'token' from c)), 0, 'raw token not stored');
select is((select count(*)::int from ruhh_agent_credentials where token_hash = ruhh_token_hash((select r->>'token' from c))), 1, 'hash stored');
select throws_ok($q$select public.ruhh_agent_credential_create('00000000-0000-4000-8000-0000000000c1', 'x', array['admin'])$q$, '23514', null, 'unknown scope rejected');
select ok(public.ruhh_agent_credential_revoke((select (r->>'credential_id')::uuid from c)), 'credential revocable');

select * from finish();
rollback;
