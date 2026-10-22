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
| `20261022160000_security_maintenance.sql` | additive | none (cleanup job) |
| `20261022170000_legacy_mitigations.sql` | additive, replaces v1 function bodies | none in normal use; rate limits + bulk-delete guard on v1 |
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
for anyone who can call v1, so S2 should follow R1 adoption **quickly** — exact criteria in
`docs/LEGACY_MITIGATIONS.md`. The interim v1 limits do **not** remove the `pin_hash` exposure. S2 does not drop v1 functions because
v2 delegates to them.

## Remote command rules (apply to every command below)
* **Never** `supabase link` this working copy to production and **never** use `--linked`
  for anything that targets production. Every remote command names its target explicitly:
  `--project-ref <REF>` for commands that support it (`functions deploy`, `secrets set`,
  `secrets list`), `--db-url "$RUHH_TARGET_DB_URL"` for commands that do not
  (`db push`, `db dump`, `migration list`). The URL comes from an environment variable set
  from the password manager for this shell only; never paste it into chat, docs or history.
* **Guard step** — run immediately before each remote command, in the same shell:

  ```bash
  : "${RUHH_TARGET_REF:?set RUHH_TARGET_REF}" "${RUHH_TARGET_DB_URL:?set RUHH_TARGET_DB_URL}"
  case "$RUHH_TARGET_DB_URL" in *"$RUHH_TARGET_REF"*) ;; *) echo "URL does not match ref"; exit 1;; esac
  [ -e supabase/.temp/project-ref ] && { echo "working copy is linked - use a fresh clone"; exit 1; }
  echo "TARGET: $RUHH_TARGET_REF  (prod is gmmfimwumtbneynsyimz)"; read -r -p "type the ref to continue: " x
  [ "$x" = "$RUHH_TARGET_REF" ] || exit 1
  ```
* Commands marked **DESTRUCTIVE** change or remove data/schema on the target and need a
  fresh backup (Phase 3 preconditions) and an explicit owner **[GATE]** approval.
* `supabase/scripts/wipe_all_user_data.sql` is **DESTRUCTIVE — deletes every user and all
  synced data**. It is never part of this rollout. Do not run it against production.

## Phase 1 — create isolated staging (free tier, separate project)
1. In the Supabase account that owns prod, create project `ruhh-staging` in the same region.
   Save its DB password straight into a password manager (never in chat or the repo).
2. Use a **fresh clone**; do not link it. Set `RUHH_TARGET_REF=<STAGING_REF>` and
   `RUHH_TARGET_DB_URL` (staging connection string) in the shell.
3. Guard step → `supabase db push --db-url "$RUHH_TARGET_DB_URL" --dry-run` (must list all 17
   migrations on an empty project) → **[GATE]** guard step →
   **DESTRUCTIVE (schema change)** `supabase db push --db-url "$RUHH_TARGET_DB_URL"`.
4. pgTAP on staging: guard step → `psql "$RUHH_TARGET_DB_URL" -f supabase/tests/0X_*.sql`
   for each file (each file is wrapped in `begin … rollback`, so it leaves no data).
5. Edge function on staging: guard step →
   `supabase functions deploy ruhh-agent --project-ref "$RUHH_TARGET_REF"` and
   `supabase secrets set --project-ref "$RUHH_TARGET_REF" RUHH_AGENT_WRITES=off`.
6. Dev build against staging: back up `ruhh/.env`, put the staging URL + anon key in it,
   build, and **restore the prod `.env` before any release build**.

## Phase 2 — staging validation (all synthetic accounts)
Run `docs/TEST_CHECKLIST.md` sections A–H on staging with both an R1 build and the
current store build (1.0.30) installed on separate devices. Run the legacy-mitigation
monitoring query from `docs/LEGACY_MITIGATIONS.md` and confirm old-app traffic is `ok`.

## Phase 3 — production rollout
Set `RUHH_TARGET_REF=gmmfimwumtbneynsyimz` and the prod `RUHH_TARGET_DB_URL` in a fresh
shell, in a fresh **unlinked** clone at the reviewed commit.

Preconditions for every **[GATE]**:
* fresh **backup**: Dashboard → Database → Backups (daily backup present) **and** a logical
  dump taken immediately before (guard step first):
  `supabase db dump --db-url "$RUHH_TARGET_DB_URL" -f prod-schema.sql` and
  `supabase db dump --db-url "$RUHH_TARGET_DB_URL" --data-only -f prod-data.sql`
  (contains PIN hashes: store encrypted, off-repo, delete after the retention window);
  verify the dump restores into a scratch project before proceeding;
* guard step → `supabase db push --db-url "$RUHH_TARGET_DB_URL" --dry-run`;
  the diff must be exactly the six additive migrations `20261022120000`…`20261022170000`;
* staging checklist green.

Steps:
1. **[GATE] P1 — DESTRUCTIVE (schema change)** — guard step →
   `supabase db push --db-url "$RUHH_TARGET_DB_URL"` (S1, inbox, agent_api, proposals,
   maintenance, legacy mitigations). Immediately verify: old store app can still log in on a
   fresh install and sync; `select has_table_privilege('anon','public.budget_objectives','select')`
   is false; legacy monitoring query shows `ok` rows.
2. **[GATE] R1** — release the app (bump version, e.g. 1.0.31). R1 works against both
   S1 and pre-S1 servers.
3. Monitor adoption: `select client_version, count(*) from ruhh_sessions group by 1;`,
   users without `pin_bcrypt`, and v1 volume (`docs/LEGACY_MITIGATIONS.md`).
4. **[GATE] min version** — SQL editor on the confirmed project:
   `update ruhh_app_config set value='1.0.31' where key='min_supported_version';`
5. **[GATE] S2 — DESTRUCTIVE (breaks pre-R1 cloud sync)** — only when every retirement
   criterion in `docs/LEGACY_MITIGATIONS.md` holds. Copy `pending/S2_retire_legacy_auth.sql`
   into `migrations/` with a new timestamp, re-run backup + guard + dry-run, then
   `supabase db push --db-url "$RUHH_TARGET_DB_URL"`.
6. **[GATE] agent** — guard step →
   `supabase functions deploy ruhh-agent --project-ref "$RUHH_TARGET_REF"`;
   `supabase secrets set --project-ref "$RUHH_TARGET_REF" RUHH_AGENT_DEFAULT_UTC_OFFSET_MIN=330 RUHH_AGENT_WRITES=off`;
   mint a read-only credential in the SQL editor, connect Grok Bot, run checklist G.
7. **[GATE] agent writes** — only after checklist H passes on staging *and* prod read-only
   use has been verified: `supabase secrets set --project-ref "$RUHH_TARGET_REF" RUHH_AGENT_WRITES=on`
   and mint a `{read,write}` credential; revoke the read-only one. Approvals happen only in
   the app (Settings → Agent approvals); the agent cannot approve.

## Rollback
Always: guard step, fresh backup, owner **[GATE]**. Schema rollbacks are **DESTRUCTIVE**.

### Schema changes
| Change | Rollback | Consequences |
|---|---|---|
| S1 breaks old app login/sync | v1 functions keep their signatures; check grants: `grant execute on function public.ruhh_fetch_auth_profile(text), public.ruhh_pull(uuid,text), public.ruhh_push(uuid,text,jsonb) to anon, authenticated;` | none for sessions |
| Legacy mitigation blocks real users (rate limit / `mass_delete_blocked`) | raise limits in place, or restore the original `language sql` `ruhh_fetch_auth_profile` from `20260318120000_ruhh_init.sql` and rename `ruhh_pull_core`/`ruhh_push_core` back (drop the wrappers first) | only limits/logging/guard removed; v2 unaffected |
| Need to undo S1 budget-table RLS | `alter table … disable row level security;` (re-opens the hole — avoid) | none |
| New tables must go | drop order: proposals → requests → audit → credentials → inbox → legacy_calls → sessions/login_attempts/app_config. Only after S2 is reverted, because R1 needs sessions. | every R1 session is destroyed; R1 falls back to v1 (if still granted) |

### Sessions
| Situation | Action | Consequences |
|---|---|---|
| Session table compromise | `update ruhh_sessions set revoked_at = now() where revoked_at is null;` | every R1 user must re-enter PIN; offline use unaffected; pending inbox items stay queued |
| Agent misbehaves | `supabase secrets set --project-ref "$RUHH_TARGET_REF" RUHH_AGENT_WRITES=off` and/or `select ruhh_agent_credential_revoke('<id>');`; pending inbox rows: `update ruhh_agent_inbox set status='rejected', error='operator_cancel' where status='pending';` | app ignores rejected rows; proposals can no longer be approved |

### App-version compatibility
| Server state | Pre-R1 app (≤ 1.0.30) | R1 app |
|---|---|---|
| before P1 | works (v1) | works (v1 fallback) |
| P1 applied | works (v1, rate-limited, deletion guard) | works (v2 sessions) |
| P1 rolled back (tables dropped) | works | sessions gone → v1 fallback; agent approvals unavailable |
| S2 applied | cloud login/sync fails; offline works | works |
| S2 rolled back | works again | works |
| R1 release pulled after S2 | — | existing installs keep working; fix forward with R1.1 |

**An S2 rollback re-opens every v1 risk**: `ruhh_fetch_auth_profile` returns `pin_hash` to
anyone with the anon key again, and v1 pull/push accept pass-the-hash for every account,
including accounts that already moved to R1. Time-box it, keep the legacy mitigations in
place, and re-apply S2 as soon as possible. After S2 also lower `min_supported_version`
only if R1 itself is the problem.

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
