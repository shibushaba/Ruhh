# Connecting Grok Bot to `ruhh-agent` (not enabled)

Status: **not connected**. Telegram is not enabled. This describes the intended wiring once
the function is deployed to staging/production behind an approval gate.

* Endpoint: `POST https://<project-ref>.supabase.co/functions/v1/ruhh-agent`
* Header: `Authorization: Bearer ruhh_agent_<64 hex>` (dedicated agent credential).
* Body: `{"op": "budget.summary", "params": {"from": "2026-10-01", "to": "2026-10-31"}, "request_id": "<unique 8-64 chars>"}`
* Response: `{"ok": true, "data": …, "meta": {"range", "modules", "coverage", "notes"}}` or
  `{"ok": false, "error": {"code"}}`.

Credential lifecycle (project owner, SQL editor — never via chat):
```sql
select ruhh_agent_credential_create('<ruhh user uuid>', 'grok-bot', array['read'], 90);
-- returns the token ONCE; store it only in the bot's secret store
select ruhh_agent_credential_revoke('<credential id>');
```

The service-role key stays inside the Edge Function environment; the bot only ever holds
the agent token. A fresh `request_id` per user intent makes retries safe.

Write operations (`tx.add`, `habit.mark_done`, `prayer.set_status`, `movie.add_watchlist`,
`tx.edit`/`tx.delete`/`movie.delete` → proposals, `proposal.approve`/`reject`) exist but are
disabled server-side until `RUHH_AGENT_WRITES=on`. The bot must show the proposal summary to
the user and call `proposal.approve` only with the exact `proposal_id` + `params_hash` after
the user confirms.
