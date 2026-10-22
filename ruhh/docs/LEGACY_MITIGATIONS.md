# Legacy (v1) API: interim mitigations and S2 retirement criteria

Migration: `supabase/migrations/20261022170000_legacy_mitigations.sql`
Tests: `supabase/tests/07_legacy_mitigations_test.sql`

## What is still exposed until S2 (read this first)

**These mitigations do NOT eliminate the PIN-hash exposure.** Until S2 is applied:

* anyone with the public anon key (it ships in every APK) can call `ruhh_fetch_auth_profile`
  for a username and receive that account's `pin_hash` and `pin_salt`;
* with that hash they can call v1 `ruhh_pull` (read all of the account's synced data) and
  v1 `ruhh_push` (overwrite it);
* a 6-digit PIN can be recovered offline from `pin_hash` + `pin_salt` in seconds.

The repository is public, so this is documented to attackers as well. S2 is the only fix.

## What the interim mitigations do

| Mitigation | Limit | Effect on the old app |
|---|---|---|
| `ruhh_fetch_auth_profile` rate limit | 20 calls / username / hour, 1000 / hour globally | none in normal use (called once per new-device login); when hit, the old app shows "User not found" for up to an hour |
| `ruhh_fetch_auth_profile` logging | metadata only: username, time, gateway IP (`x-forwarded-for`), outcome | none |
| v1 `ruhh_pull` / `ruhh_push` rate limit | 1200 accepted calls / user / hour | none in normal use (~1–3 calls per sync, about one sync a minute) |
| v1 `ruhh_push` mass-deletion guard | refuse if a push would delete **> 50 rows AND > 50 %** of the user's synced rows; completions of a habit deleted in the same push are not counted | single deletes, deleting a habit with long history and the empty-payload guard keep working; a genuine bulk delete on the OLD app fails with `mass_delete_blocked` until the user updates to R1 (v2 is not guarded) |

They make bulk harvesting slower and visible and stop a single forged push from wiping most of an
account. They do not stop a targeted attacker who needs one `fetch_auth_profile` call.
Only accepted calls count towards the pull/push limits (a refused call rolls back its own log row).
`ruhh_legacy_calls` prunes itself (rows older than 2 days).

Monitoring query (SQL editor on the target project, read-only):

```sql
select fn, outcome, date_trunc('hour', created_at) h, count(*), count(distinct key) keys, count(distinct ip) ips
from ruhh_legacy_calls where created_at > now() - interval '48 hours'
group by 1, 2, 3 order by 3 desc, 1;
```

## S2 retirement criteria (all must hold)

1. **R1 adoption**: at least **95 %** of accounts active in the last 30 days have used a v2 session
   (`select count(distinct user_id) from ruhh_sessions where created_at > now() - interval '30 days'`
   versus distinct `key` in `ruhh_legacy_calls` for `pull` over the same window — keep a daily
   snapshot because the table only keeps 2 days).
2. **Minimum version raised**: `min_supported_version` set to the R1 version for at least **14 days**
   (this only blocks old *R-series* clients from new logins; pre-R1 apps never call it — the
   forcing step for them is S2 itself).
3. **v1 volume**: v1 `pull`/`push` calls have been below **5 % of total sync calls for 7 consecutive
   days**, and every remaining v1 user id has been contacted (in-app banner in R1, store notes).
4. **Date**: no later than **30 days after the R1 release reaches 100 % rollout** — if the criteria
   above are not met by then, apply S2 anyway (the exposure is public) and accept that the
   remaining old-app users must update.
5. Backup taken and target project re-confirmed (see SECURITY_ROLLOUT.md, Phase 2 gates).

## Rollback consequences

* Rolling back **this mitigation** (re-creating the original `language sql` fetch function and
  renaming `*_core` back) only removes rate limits/logging/guard; nothing else changes.
* Rolling back **S2** (re-granting v1) **re-opens the full pass-the-hash and v1 push exposure**
  described above for every account, including accounts that already moved to R1 (their
  `pin_hash` still exists). Time-box it, re-apply S2 as soon as possible.
