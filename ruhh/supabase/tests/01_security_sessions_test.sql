-- pgTAP: S1 security + sessions. Synthetic data only; runs inside a rolled-back transaction.
begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;

select plan(54);

-- ---------- anon/authenticated have no direct table access ----------
select ok(not has_table_privilege('anon', 'public.' || t, 'SELECT,INSERT,UPDATE,DELETE'),
          'anon has no direct access to ' || t)
from unnest(array['users','transactions','habits','habit_completions','prayer_logs','movies',
                  'budget_objectives','category_budget_limits','ruhh_sessions',
                  'ruhh_login_attempts','ruhh_app_config']) t;

select ok(not has_table_privilege('authenticated', 'public.budget_objectives', 'SELECT,INSERT,UPDATE,DELETE'),
          'authenticated has no direct access to budget_objectives');
select ok(not has_table_privilege('authenticated', 'public.category_budget_limits', 'SELECT,INSERT,UPDATE,DELETE'),
          'authenticated has no direct access to category_budget_limits');
select ok((select relrowsecurity from pg_class where oid = 'public.budget_objectives'::regclass), 'RLS on budget_objectives');
select ok((select relrowsecurity from pg_class where oid = 'public.category_budget_limits'::regclass), 'RLS on category_budget_limits');

-- ---------- function grants ----------
select ok(not has_function_privilege('anon', 'public.ruhh_verify_user(uuid,text)', 'EXECUTE'), 'anon cannot call ruhh_verify_user');
select ok(not has_function_privilege('authenticated', 'public.ruhh_verify_user(uuid,text)', 'EXECUTE'), 'authenticated cannot call ruhh_verify_user');
select ok(not has_function_privilege('anon', 'public.ruhh_session_user(text)', 'EXECUTE'), 'anon cannot call ruhh_session_user');
select ok(not has_function_privilege('anon', 'public.ruhh_issue_session(uuid,text)', 'EXECUTE'), 'anon cannot call ruhh_issue_session');
select ok(has_function_privilege('anon', 'public.ruhh_login(text,text,text)', 'EXECUTE'), 'anon can call ruhh_login');
select ok(has_function_privilege('anon', 'public.ruhh_pull_v2(text)', 'EXECUTE'), 'anon can call ruhh_pull_v2');

-- every SECURITY DEFINER function in public pins its search_path
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prosecdef
     and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%')),
  0, 'all SECURITY DEFINER functions set search_path');

-- ---------- registration ----------
select is((public.ruhh_register_user_v2('00000000-0000-4000-8000-00000000000a', '  Alice_Test ', '123456', '1.0.31'))->>'ok',
          'true', 'register v2 ok');
select is((public.ruhh_register_user_v2(gen_random_uuid(), 'alice_test', '123456', '1.0.31'))->>'error',
          'username_taken', 'register v2 rejects taken username (case-insensitive)');
select is((public.ruhh_register_user_v2(gen_random_uuid(), 'ab', '123456', '1.0.31'))->>'error',
          'username_too_short', 'register v2 rejects short username');
select is((public.ruhh_register_user_v2(gen_random_uuid(), 'bob_x', '12', '1.0.31'))->>'error',
          'invalid_pin', 'register v2 rejects malformed PIN');
select ok((select pin_bcrypt like '$2a$%' from users where id = '00000000-0000-4000-8000-00000000000a'),
          'register v2 stores bcrypt verifier');
select is((select pin_hash from users where id = '00000000-0000-4000-8000-00000000000a'),
          (select encode(digest(pin_salt || ':123456', 'sha256'), 'hex') from users where id = '00000000-0000-4000-8000-00000000000a'),
          'register v2 also stores legacy-compatible sha256(salt:pin)');

-- legacy user (registered by an old app with v1): no bcrypt yet
select public.ruhh_register_user('00000000-0000-4000-8000-00000000000b', 'legacy_bob', encode(digest('s4lt:654321', 'sha256'), 'hex'), 's4lt');

-- ---------- login ----------
select is((public.ruhh_login('legacy_bob', '654321', '1.0.31'))->>'ok', 'true', 'legacy user logs in with correct PIN');
select ok((select pin_bcrypt is not null from users where username = 'legacy_bob'), 'login upgrades legacy user to bcrypt');
select is((select pin_hash from users where username = 'legacy_bob'), encode(digest('s4lt:654321', 'sha256'), 'hex'),
          'legacy hash preserved for old app versions');
select is((public.ruhh_login('LEGACY_BOB', '654321', '1.0.31'))->>'ok', 'true', 'login after bcrypt upgrade (case-insensitive)');
select is((public.ruhh_login('legacy_bob', '000000', '1.0.31'))->>'error', 'invalid_credentials', 'wrong PIN rejected');
select is((public.ruhh_login('nobody_here', '000000', '1.0.31'))->>'error', 'invalid_credentials', 'unknown user gets the same error');
select ok(not ((public.ruhh_login('nobody_here', '000000', '1.0.31')) ? 'pin_hash'), 'login failure leaks no pin_hash');

create temp table t_login as select public.ruhh_login('alice_test', '123456', '1.0.31') as r;
select ok(not ((select r from t_login) ? 'pin_hash'), 'login success returns no pin_hash');
select ok((select r->>'token' ~ '^[0-9a-f]{64}$' from t_login), 'token is 32 random bytes (hex)');
select is((select count(*)::int from ruhh_sessions where token_hash = (select r->>'token' from t_login)), 0,
          'raw token is not stored');
select is((select count(*)::int from ruhh_sessions where token_hash = ruhh_token_hash((select r->>'token' from t_login))), 1,
          'only sha256(token) is stored');
select ok((select expires_at between now() + interval '29 days' and now() + interval '31 days'
           from ruhh_sessions where token_hash = ruhh_token_hash((select r->>'token' from t_login))), '30-day expiry');

-- lockout: 5 failures in 15 min
select public.ruhh_login('alice_test', '999999', '1.0.31') from generate_series(1, 5);
select is((public.ruhh_login('alice_test', '123456', '1.0.31'))->>'error', 'locked_out', 'locked out after 5 failures even with correct PIN');
update ruhh_login_attempts set created_at = now() - interval '16 minutes' where username_key = 'alice_test';
select is((public.ruhh_login('alice_test', '123456', '1.0.31'))->>'ok', 'true', 'lockout expires after 15 minutes');

-- min version
update ruhh_app_config set value = '1.0.31' where key = 'min_supported_version';
select is((public.ruhh_login('alice_test', '123456', '1.0.30'))->>'error', 'update_required', 'old client told to update');
select is((public.ruhh_login('alice_test', '123456', 'garbage'))->>'error', 'update_required', 'unparseable version treated as too old');
update ruhh_app_config set value = '0.0.0' where key = 'min_supported_version';

-- ---------- sync v2 round trip + isolation ----------
select lives_ok(format($q$select public.ruhh_push_v2(%L, '{"transactions":[{"id":"10000000-0000-4000-8000-000000000001","amount":42,"category":"Food","occurred_at":"2026-10-01T10:00:00Z"}]}'::jsonb)$q$,
  (select r->>'token' from t_login)), 'push_v2 with valid token');
select is(jsonb_array_length((public.ruhh_pull_v2((select r->>'token' from t_login)))->'transactions'), 1, 'pull_v2 returns pushed row');
select ok(not (public.ruhh_pull_v2((select r->>'token' from t_login)) ? 'pin_hash'), 'pull_v2 output has no pin_hash');

-- empty-payload guard: empty push must not wipe
select public.ruhh_push_v2((select r->>'token' from t_login), '{}'::jsonb);
select is((select count(*)::int from transactions where user_id = '00000000-0000-4000-8000-00000000000a'), 1, 'empty payload does not wipe rows');

-- isolation: bob's token sees none of alice's rows
create temp table t_bob as select public.ruhh_login('legacy_bob', '654321', '1.0.31') as r;
select is(jsonb_array_length((public.ruhh_pull_v2((select r->>'token' from t_bob)))->'transactions'), 0, 'user B cannot read user A rows');
select public.ruhh_push_v2((select r->>'token' from t_bob), '{"habits":[{"id":"20000000-0000-4000-8000-000000000001","name":"Read","color_value":1}]}'::jsonb);
select is((select count(*)::int from transactions where user_id = '00000000-0000-4000-8000-00000000000a'), 1, 'user B push does not touch user A rows');

-- invalid / expired / revoked tokens
select throws_ok($q$select public.ruhh_pull_v2('garbage')$q$, '28000', 'session_invalid', 'garbage token rejected');
update ruhh_sessions set expires_at = now() - interval '1 second' where token_hash = ruhh_token_hash((select r->>'token' from t_bob));
select throws_ok(format($q$select public.ruhh_pull_v2(%L)$q$, (select r->>'token' from t_bob)), '28000', 'session_invalid', 'expired token rejected');
select ok(public.ruhh_logout((select r->>'token' from t_login)), 'logout revokes session');
select throws_ok(format($q$select public.ruhh_push_v2(%L, '{}'::jsonb)$q$, (select r->>'token' from t_login)), '28000', 'session_invalid', 'revoked token rejected');

select * from finish();
rollback;
