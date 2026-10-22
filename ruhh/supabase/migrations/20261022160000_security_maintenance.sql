-- Retention cleanup for security/agent tables (additive). Nothing here runs automatically
-- unless pg_cron is already installed; otherwise schedule ruhh_security_cleanup() externally
-- (see docs/SECURITY_ROLLOUT.md "Maintenance").

create or replace function public.ruhh_security_cleanup()
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_sessions int;
  v_attempts int;
  v_requests int;
  v_inbox int;
  v_proposals int;
  v_audit int;
begin
  -- sessions: expired or revoked more than 7 days ago (kept briefly for incident review)
  delete from public.ruhh_sessions
  where expires_at < now() - interval '7 days'
     or revoked_at < now() - interval '7 days';
  get diagnostics v_sessions = row_count;

  -- login attempts: lockout only looks at the last 15 minutes
  delete from public.ruhh_login_attempts where created_at < now() - interval '30 days';
  get diagnostics v_attempts = row_count;

  -- idempotency records: request_id replays are only meaningful for a short time
  delete from public.ruhh_agent_requests where created_at < now() - interval '30 days';
  get diagnostics v_requests = row_count;

  -- finished inbox rows (pending rows are never deleted)
  delete from public.ruhh_agent_inbox
  where status <> 'pending' and coalesce(applied_at, created_at) < now() - interval '90 days';
  get diagnostics v_inbox = row_count;

  -- decided or long-expired proposals
  delete from public.ruhh_agent_proposals
  where (status <> 'pending' and coalesce(decided_at, created_at) < now() - interval '90 days')
     or (status = 'pending' and expires_at < now() - interval '30 days');
  get diagnostics v_proposals = row_count;

  -- metadata-only audit: 180 days
  delete from public.ruhh_agent_audit where created_at < now() - interval '180 days';
  get diagnostics v_audit = row_count;

  return jsonb_build_object('sessions', v_sessions, 'login_attempts', v_attempts,
    'agent_requests', v_requests, 'inbox', v_inbox, 'proposals', v_proposals, 'audit', v_audit);
end;
$$;

revoke all on function public.ruhh_security_cleanup() from public, anon, authenticated;
grant execute on function public.ruhh_security_cleanup() to service_role;

create index if not exists ruhh_login_attempts_created_idx on public.ruhh_login_attempts (created_at);
create index if not exists ruhh_sessions_expires_idx on public.ruhh_sessions (expires_at);

-- Optional: daily schedule, only if pg_cron is already enabled on this project.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid) from cron.job where jobname = 'ruhh_security_cleanup';
    perform cron.schedule('ruhh_security_cleanup', '17 3 * * *', 'select public.ruhh_security_cleanup()');
  end if;
end;
$$;
