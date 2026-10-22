# RUHH security + agent test checklist

Automated (run locally on this branch — see PR description for actual results):
* `supabase start` (disposable) + `supabase test db` → pgTAP files 01–04.
* `cd supabase/functions/ruhh-agent && deno fmt --check && deno lint && deno test --allow-env`.
* `flutter analyze`, `flutter test` (includes `cloud_auth_client_test.dart`, `agent_inbox_test.dart`).
* `supabase functions serve ruhh-agent --no-verify-jwt --env-file <file with RUHH_AGENT_WRITES=on>`
  then `powershell -File supabase/scripts/local_agent_smoke.ps1` (set `RUHH_SMOKE_WRITES=1` for writes).

Manual (staging, synthetic accounts only). Tick each with date + build.

## A. Database security
- [ ] anon REST `GET /rest/v1/budget_objectives` and `/category_budget_limits` → 401/permission denied
- [ ] anon RPC `ruhh_verify_user` → denied
- [ ] `ruhh_login` wrong PIN ×5 → `locked_out`; correct PIN after 15 min → ok
- [ ] unknown username → `invalid_credentials` (same as wrong PIN)
- [ ] no v2 response contains `pin_hash`

## B. Legacy compatibility (store build 1.0.30 on device 1)
- [ ] existing logged-in user keeps syncing after S1
- [ ] fresh install + login on old build works after S1 (before S2)
- [ ] after S2 (staging only): old build login on fresh install fails cleanly; local data intact

## C. R1 app (device 2)
- [ ] fresh registration → session token stored (no PIN hash sent)
- [ ] login on new device restores cloud data
- [ ] offline: airplane mode → unlock with PIN works; edits saved locally; sync resumes online
- [ ] logout → server session revoked (`ruhh_sessions.revoked_at` set); local data kept
- [ ] force-expire session (`update ruhh_sessions set expires_at=now()`) → app shows
      "Cloud session expired — log out and sign in again"; after re-login sync resumes
- [ ] `min_supported_version` above build → login shows update message; local unlock still works
- [ ] upgrade 1.0.30 → R1 with existing data: no data loss; after re-login uses v2

## D. Sync regression
- [ ] add/edit/delete transaction, objective, category limit, habit, completion, prayer, movie
      → visible on second device after sync
- [ ] empty local DB never wipes cloud (reinstall test)

## E. Inbox
- [ ] enqueue (SQL/agent) a transaction → open app → appears; after next sync still present
- [ ] kill the app right after it appears, reopen → no duplicate
- [ ] replay same request_id → one record
- [ ] habit_completion for unknown habit → rejected, app unaffected
- [ ] restart app → record still present (Isar) and in cloud

## F. Agent read (staging function, read-only credential)
- [ ] `budget.summary`, `budget.list_transactions`, `budget.upcoming`, `budget.objectives`,
      `budget.category_limits`, `habit.list`, `habit.completions`, `prayer.summary`,
      `movie.list`, `cross.monthly_report` return explicit ranges + notes
- [ ] revoked credential → 401; second user's data never visible
- [ ] function logs contain no amounts/titles/tokens

## G. Telegram / Grok Bot (read-only)
- [ ] "How much did I spend on food this month?" → matches app; states the date range
- [ ] "Compare my prayers and habits last week" → cross-module answer with missing-data notes
- [ ] Motta's existing routines and Telegram behaviour unchanged

## H. Agent writes (only after E passes; `RUHH_AGENT_WRITES=on` on staging)
- [ ] "Add ₹120 tea expense" → queued → appears after app sync → still there after restart
- [ ] "Mark Read done today", "Asr prayed on time", "Add Dune to watchlist" → applied once
- [ ] "Delete that transaction" → bot replies "approve in the app"; bot response has no params_hash
- [ ] bot asked to approve → it cannot (no op exists; `proposal.approve` → 400 unknown_op)
- [ ] RUHH → Settings → Agent approvals shows the readable summary; Approve → applied after sync
- [ ] approve twice / after 15 min / after editing the transaction → rejected with a clear message
- [ ] a second phone signed in as another user sees no proposals of the first user
- [ ] payments, transfers, bulk edits, wallet/todo changes → refused
