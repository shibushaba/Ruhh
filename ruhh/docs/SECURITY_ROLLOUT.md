# RUHH security + agent rollout

Branch `feature/security-session-agent`. Nothing in this branch has been applied to
production (`gmmfimwumtbneynsyimz`) or to any remote Supabase project. Every step below
that touches a remote project needs explicit approval from the owner at the gate marked
**[GATE]**.

## What changes

| Piece | Kind | Effect on installed apps |
|---|---|---|
| `20261022120000_security_sessions_s1.sql` (S1) | additive migration | none — v1 RPCs unchanged |
| `20261022130000_agent_inbox.sql` | additive | none |
| `20261022140000_agent_api.sql` | additive | none |
| `20261022150000_agent_proposals.sql` | additive | none |
| App release **R1** (session tokens) | client | uses v2; falls back to v1 if the server lacks v2 |
| `supabase/pending/S2_retire_legacy_auth.sql` (S2) | **breaking** for pre‑R1 apps | old apps can no longer cloud-login/sync (offline use continues) |
| `functions/ruhh-agent` | new Edge Function | none; writes disabled unless `RUHH_AGENT_WRITES=on` |

### S1 summary
* RLS enabled + `revoke all` from `anon`/`authenticated` on `budget_objectives`,
  `category_budget_limits` (no `FORCE`, so the SECURITY DEFINER sync functions keep working).
* `ruhh_verify_user` no longer executable by `public`/`anon`/`authenticated`.
* `users.pin_bcrypt` (bcrypt via pgcrypto) set on first successful server login; legacy
  `pin_hash`/`pin_salt` are kept so pre‑R1 apps continue to work until S2.
* `ruhh_sessions` (sha256 of a 32-byte random token, 30-day expiry, revocation),
  `ruhh_login_attempts` (5 failures / 15 min lockout, also for unknown usernames),
  `ruhh_app_config` (`min_supported_version`, `session_ttl_days`).
* New API: `ruhh_login`, `ruhh_register_user_v2`, `ruhh_logout`, `ruhh_pull_v2`,
  `ruhh_push_v2`, `ruhh_session_info_v2`. Uniform `invalid_credentials` for wrong PIN and
  unknown user; no function returns `pin_hash`.
* `ruhh_pull_v2`/`ruhh_push_v2` resolve the session server-side, then call the existing
  v1 implementation as the owner — identical reconcile semantics and empty-payload guard.

### Why S2 is not a migration
S2 makes `ruhh_fetch_auth_profile` return nothing and revokes `ruhh_pull`, `ruhh_push`,
`ruhh_register_user` from API roles. Until S2 runs, the pass-the-hash hole remains open
for anyone who can call v1, so S2 should follow R1 adoption **quickly** (target: ≤ 2–4
weeks after R1 is on the store, not indefinitely). S2 does not drop v1 functions because
v2 delegates to them.

## Phase 1 — create isolated staging (free tier, separate project)
1. In the Supabase account that owns prod, create project `ruhh-staging` in the same region.
   Save its DB password straight into a password manager (never in chat or the repo).
2. Use a **fresh clone**. Before every command run `cat supabase/.temp/project-ref` and
   confirm it is the staging ref, never `gmmfimwumtbneynsyimz`.
3. `supabase login` → `supabase link --project-ref <STAGING_REF>` →
   `supabase db push --dry-run` (must list all 15 migrations) → **[GATE]** `supabase db push`.
4. `supabase test db --linked` is not supported for remote; instead run the pgTAP files
   with `psql "$STAGING_DB_URL" -f supabase/tests/0X_*.sql` (each file is wrapped in
   `begin … rollback`, so it leaves no data).
5. Dev build against staging: back up `ruhh/.env`, put the staging URL + anon key in it,
   build, and **restore the prod `.env` before any release build**.

## Phase 2 — staging validation (all synthetic accounts)
Run `docs/TEST_CHECKLIST.md` sections A–F on staging with both an R1 build and the
current store build (1.0.30) installed on separate devices.

## Phase 3 — production rollout
Preconditions for every **[GATE]**:
* fresh **backup**: Dashboard → Database → Backups (daily backup present) **and** a logical
  dump taken immediately before: `supabase db dump --linked -f prod-schema.sql` and
  `supabase db dump --linked --data-only -f prod-data.sql` (store encrypted, off-repo);
  verify the dump restores into a scratch project before proceeding;
* re-confirm target ref `gmmfimwumtbneynsyimz` and run `supabase db push --dry-run`;
  the diff must be exactly the four additive migrations;
* staging checklist green.

Steps:
1. **[GATE] P1** — apply S1 + inbox + agent_api + proposals (`supabase db push`).
   Immediately verify: old store app can still log in on a fresh install and sync;
   `select has_table_privilege('anon','public.budget_objectives','select')` is false.
2. **[GATE] R1** — release the app (bump version, e.g. 1.0.31). R1 works against both
   S1 and pre-S1 servers.
3. Monitor adoption: `select client_version, count(*) from ruhh_sessions group by 1;`
   and users without `pin_bcrypt`.
4. **[GATE] min version** — `update ruhh_app_config set value='1.0.31' where key='min_supported_version';`
5. **[GATE] S2** — copy `pending/S2_retire_legacy_auth.sql` into `migrations/` with a new
   timestamp, re-run the backup + dry-run gate, push.
6. **[GATE] agent** — deploy `ruhh-agent` (`supabase functions deploy ruhh-agent`), set
   secrets (`RUHH_AGENT_DEFAULT_UTC_OFFSET_MIN=330`; `RUHH_AGENT_WRITES` stays `off`),
   mint a read-only credential in the SQL editor, connect Grok Bot, run checklist G.
7. **[GATE] agent writes** — only after checklist H passes on staging *and* prod read-only
   use has been verified: set `RUHH_AGENT_WRITES=on` and mint a `{read,write,approve}`
   credential; revoke the read-only one.

## Rollback (accounts for sessions and app versions)
| Situation | Rollback | Consequences |
|---|---|---|
| S1 breaks old app login/sync | v1 functions are untouched by S1, so this indicates a grant problem: `grant execute on function public.ruhh_fetch_auth_profile(text), public.ruhh_pull(uuid,text), public.ruhh_push(uuid,text,jsonb) to anon, authenticated;` | none for sessions |
| Need to undo S1 budget-table RLS | `alter table … disable row level security;` (re-opens the hole — avoid) | none |
| R1 app broken | pull release; R1 users still work on v1 fallback **only before S2**. Fix forward with R1.1. | sessions stay valid |
| S2 breaks too many users | re-run original `ruhh_fetch_auth_profile` from `20260318120000_ruhh_init.sql` and re-grant the three v1 functions. **This re-opens pass-the-hash**; time-box it. | R1 sessions unaffected; lower `min_supported_version` again |
| Session table compromise | `update ruhh_sessions set revoked_at = now() where revoked_at is null;` | every R1 user must re-enter PIN; offline use unaffected |
| Agent misbehaves | `RUHH_AGENT_WRITES=off` (kill switch) and/or `select ruhh_agent_credential_revoke('<id>');`; pending inbox rows: `update ruhh_agent_inbox set status='rejected', error='operator_cancel' where status='pending';` | app ignores rejected rows |
| New tables must go | drop order: proposals → requests → audit → credentials → inbox → sessions/login_attempts/app_config. Only after S2 is reverted, because R1 needs sessions. | all R1 users fall back to v1 (if still granted) |

A plain re-grant is **not** a full rollback once S2 is in place or once R1 users depend on
sessions — use the table above.

## Remaining decisions / known limitations
* PIN space is 6 digits; bcrypt + lockout slows online guessing, but an offline attacker with
  a DB dump can still brute-force 10^6 PINs. Longer PINs would need a UX change.
* Lockout is per username, so an attacker can lock a known user out for 15 min (DoS
  trade-off). Consider per-IP limits at the edge later.
* Users who stay logged in on an old build keep syncing via v1 until S2; after S2 they see
  "log out and sign in again". No data is lost (local-first).
* Inbox actions apply only when the phone opens and syncs; the agent reports them as `queued`.
* Prayer actions write `PrayerLogLocal` (the synced model); the daily tracker view is
  rehydrated on the next full sync (≤ 45 s while open).
* Habit "mark done" toggles only if not already done (idempotent), via `HabitRepository`.
* Agent rate limit is 30 requests/min per credential, counted from the audit table.
