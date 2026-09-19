-- Destructive: removes every RUHH user and all synced rows (children cascade from users).
-- Run: supabase db execute --file supabase/scripts/wipe_all_user_data.sql --linked

truncate table public.users restart identity cascade;
