-- =====================================================================================
-- DESTRUCTIVE - DELETES EVERY RUHH USER AND ALL SYNCED DATA (children cascade from users).
-- IRREVERSIBLE without a backup. NEVER run against production (gmmfimwumtbneynsyimz).
-- Intended only for a local stack or a disposable staging project:
--   local:   psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -f supabase/scripts/wipe_all_user_data.sql
--   staging: run the guard step from docs/SECURITY_ROLLOUT.md first, then
--            psql "$RUHH_TARGET_DB_URL" -f supabase/scripts/wipe_all_user_data.sql
-- Never use --linked.
-- =====================================================================================

truncate table public.users restart identity cascade;
