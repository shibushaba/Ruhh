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
`tx.edit`/`tx.delete`/`movie.delete` → proposals, `proposal.list`, `proposal.reject`) exist but
are disabled server-side until `RUHH_AGENT_WRITES=on`.

## Approval is user-only (the agent can never approve)

* There is no `proposal.approve` operation and no `approve` credential scope; the agent's
  service-role path has no EXECUTE on the approve function, and the agent never receives a
  proposal's `params_hash`.
* Edits/deletes return `requires_approval: true` with a readable `summary`. The bot should tell
  the user: "Open RUHH → Settings → Agent approvals to approve or reject."
* The app lists pending proposals with `ruhh_proposals_list_v2(session token)` and decides with
  `ruhh_proposal_decide_v2(session token, proposal_id, params_hash, decision)`. The session token
  comes from the user's own PIN login on the phone. The server re-checks owner, pending, expiry
  (15 min), exact hash, target existence and (for edits) that the transaction is unchanged since
  the proposal, under a row lock, single use.
* The bot may `proposal.reject` (always safe).

Future option (not implemented, not relied upon): a Telegram one-time code — the app shows a
6-digit code bound to `proposal_id + params_hash`, stored hashed with a 5-minute expiry and 3
attempts; the user types it into Telegram and the server verifies it. It would still require
the app (a second factor the bot does not hold); a code generated or relayed by the bot itself
would not be acceptable.
