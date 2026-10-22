-- S2: retire legacy pass-the-hash access.  NOT A MIGRATION. Do not copy into
-- supabase/migrations/ until ALL of these hold (see docs/SECURITY_ROLLOUT.md):
--   * App release R1 (session tokens) has been live long enough for active users to update;
--   * ruhh_app_config.min_supported_version is set to the R1 version;
--   * staging has run S1+S2 with pgTAP green and a manual R1 + legacy-client check;
--   * a verified prod backup exists and the target ref has been re-confirmed.
-- Effect: old app versions (< R1) can no longer log in on a new device or sync;
-- they keep working fully offline. ruhh_pull/ruhh_push stay defined because the v2
-- wrappers call them as the owner.

-- 1. Stop leaking verifier material. Keep the function (old clients get null => "User not found").
create or replace function public.ruhh_fetch_auth_profile(p_username text)
returns jsonb
language sql
security definer
set search_path = public
as $$
  select 'null'::jsonb;
$$;
revoke execute on function public.ruhh_fetch_auth_profile(text) from public, anon, authenticated;

-- 2. Legacy hash-authenticated sync and registration are no longer callable from the API.
revoke execute on function public.ruhh_pull(uuid, text) from public, anon, authenticated;
revoke execute on function public.ruhh_push(uuid, text, jsonb) from public, anon, authenticated;
revoke execute on function public.ruhh_register_user(uuid, text, text, text) from public, anon, authenticated;

-- 3. Users who never logged in with R1 have no bcrypt verifier yet; they can still
--    log in via ruhh_login (legacy sha256 path, upgraded on success). Nothing to do here.

-- Rollback (only if R1 is broken AND you accept re-opening the hole temporarily):
--   re-run the original ruhh_fetch_auth_profile from 20260318120000_ruhh_init.sql and
--   grant execute on the four functions to anon, authenticated. Sessions are unaffected.
