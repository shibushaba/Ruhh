-- Legacy (old app, v1) flows still work; abuse is limited. Synthetic data only.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(24);

-- privileges: wrappers keep old grants, internals are closed
select ok(has_function_privilege('anon', 'public.ruhh_fetch_auth_profile(text)', 'EXECUTE'), 'old app: fetch_auth_profile still callable');
select ok(has_function_privilege('anon', 'public.ruhh_pull(uuid,text)', 'EXECUTE'), 'old app: v1 pull still callable');
select ok(has_function_privilege('anon', 'public.ruhh_push(uuid,text,jsonb)', 'EXECUTE'), 'old app: v1 push still callable');
select ok(not has_function_privilege('anon', 'public.ruhh_pull_core(uuid,text)', 'EXECUTE'), 'pull_core internal');
select ok(not has_function_privilege('anon', 'public.ruhh_push_core(uuid,text,jsonb)', 'EXECUTE'), 'push_core internal');
select ok(not has_function_privilege('anon', 'public.ruhh_legacy_note(text,text,text)', 'EXECUTE'), 'note internal');
select ok(not has_table_privilege('anon', 'public.ruhh_legacy_calls', 'SELECT'), 'legacy log not readable');

-- old-app account
select public.ruhh_register_user('00000000-0000-4000-8000-0000000000b1', 'legacy_bea', 'hashB', 'saltB');
select is(public.ruhh_fetch_auth_profile('Legacy_Bea')->>'pin_hash', 'hashB', 'old app new-device login: profile returned');

create temp table pl as select jsonb_build_object(
  'transactions', (select jsonb_agg(jsonb_build_object('id', format('40000000-0000-4000-8000-%s', lpad(g::text, 12, '0')),
    'amount', g, 'category', 'Food', 'occurred_at', '2026-10-20T08:00:00Z')) from generate_series(1, 60) g),
  'habits', jsonb_build_array(jsonb_build_object('id', '41000000-0000-4000-8000-000000000001', 'name', 'Read', 'color_value', 1),
                              jsonb_build_object('id', '41000000-0000-4000-8000-000000000002', 'name', 'Run', 'color_value', 1)),
  'habit_completions', (select jsonb_agg(jsonb_build_object('id', format('42000000-0000-4000-8000-%s', lpad(g::text, 12, '0')),
    'habit_id', '41000000-0000-4000-8000-000000000002', 'day', (date '2026-01-01' + g)::text)) from generate_series(1, 80) g)
) as p;
select lives_ok($q$select public.ruhh_push('00000000-0000-4000-8000-0000000000b1', 'hashB', (select p from pl))$q$, 'v1 push of a full snapshot works');
select is(jsonb_array_length(public.ruhh_pull('00000000-0000-4000-8000-0000000000b1', 'hashB')->'transactions'), 60, 'v1 pull works');
select throws_ok($q$select public.ruhh_pull('00000000-0000-4000-8000-0000000000b1', 'wrong')$q$, 'P0001', 'unauthorized', 'v1 pull still checks the hash');

-- legitimate single delete
select lives_ok($q$select public.ruhh_push('00000000-0000-4000-8000-0000000000b1', 'hashB',
  jsonb_set((select p from pl), '{transactions}', ((select p from pl)->'transactions') - 0))$q$, 'single delete allowed');
select is((select count(*)::int from transactions where user_id = '00000000-0000-4000-8000-0000000000b1'), 59, 'one row deleted');
-- empty-payload guard unchanged
select lives_ok($q$select public.ruhh_push('00000000-0000-4000-8000-0000000000b1', 'hashB', '{"preferences": {}}')$q$, 'empty payload accepted');
select is((select count(*)::int from transactions where user_id = '00000000-0000-4000-8000-0000000000b1'), 59, 'empty payload deletes nothing');
-- deleting a habit with 80 completions is allowed (completions of a removed habit are not counted)
select lives_ok($q$select public.ruhh_push('00000000-0000-4000-8000-0000000000b1', 'hashB',
  jsonb_build_object('transactions', ((select p from pl)->'transactions') - 0,
    'habits', jsonb_build_array((select p from pl)->'habits'->0)))$q$, 'habit + its long history can be deleted');
select is((select count(*)::int from habit_completions where user_id = '00000000-0000-4000-8000-0000000000b1'), 0, 'completions gone with habit');

-- forged "wipe" push is refused and nothing is deleted
select throws_ok($q$select public.ruhh_push('00000000-0000-4000-8000-0000000000b1', 'hashB',
  jsonb_build_object('transactions', jsonb_build_array((select p from pl)->'transactions'->1)))$q$,
  'P0001', 'mass_delete_blocked', 'mass deletion via v1 blocked');
select is((select count(*)::int from transactions where user_id = '00000000-0000-4000-8000-0000000000b1'), 59, 'nothing deleted');

-- R1 (v2) path is not affected by the guard
select public.ruhh_login('legacy_bea', '000000', '1.0.31'); -- wrong PIN (legacy sha256 of salt:pin won't match 'hashB')
update users set pin_bcrypt = crypt('135790', gen_salt('bf', 4)) where id = '00000000-0000-4000-8000-0000000000b1';
create temp table s as select public.ruhh_login('legacy_bea', '135790', '1.0.31') as r;
select lives_ok($q$select public.ruhh_push_v2((select r->>'token' from s),
  jsonb_build_object('transactions', jsonb_build_array((select p from pl)->'transactions'->1)))$q$, 'v2 push not guarded (R1 path)');

-- fetch_auth_profile per-username limit (20/hour) and logging without secrets
select public.ruhh_fetch_auth_profile('legacy_bea') from generate_series(1, 25);
select is(public.ruhh_fetch_auth_profile('legacy_bea'), 'null'::jsonb, 'harvesting one username is limited');
select is((select count(*)::int from ruhh_legacy_calls where fn = 'fetch_auth_profile' and key = 'legacy_bea' and outcome = 'limited') > 0,
  true, 'refusals are logged');
select is((select count(*)::int from ruhh_legacy_calls c where c::text like '%hashB%'), 0, 'log has no hashes');

-- v1 pull per-user limit
insert into ruhh_legacy_calls (fn, key, outcome) select 'pull', '00000000-0000-4000-8000-0000000000b1', 'ok' from generate_series(1, 1200);
select throws_ok($q$select public.ruhh_pull('00000000-0000-4000-8000-0000000000b1', 'hashB')$q$, 'P0001', 'rate_limited', 'v1 pull rate limited per user');

select * from finish();
rollback;
