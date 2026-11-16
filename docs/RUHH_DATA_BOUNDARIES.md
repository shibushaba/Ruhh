# RUHH data and sync boundaries (Phase 1)

**Status:** recommendations only. No SQL, no migration, no production access.
**Date:** 16 November 2026
**Binds with:** `RUHH_OWNER_DECISIONS.md` items 5–11 and requirements A2, A3, A6.
**Does not replace:** `RUHH_DATABASE_DESIGN.md`, which describes the schema that exists today.

## 1. What must not happen

- Do not add progression rows to the current `ruhh_push` reconcile-delete. That function deletes cloud rows whose ids are missing from a non-empty snapshot (`20261112150000_movie_categories_sync.sql` on `main`). An XP history cannot live in that pattern.
- Do not store life goals in `budget_objectives`. Those rows are savings and debt, synced in the `objectives` array, with amounts and wallet names.
- Do not store prayer as XP. Do not call `PrayerRepository.setStatus` or the SharedPreferences point keys. The live record remains `DailyPrayerLogLocal`.
- Do not award XP from `IslandLedger`.
- Do not extend `ruhh_pull` / `ruhh_push` to new tables until Gate A is approved. Decision 9 forbids growing the PIN-hash RPC surface as the way new data is saved.

## 2. Conceptual records

Names are recommendations for a later migration, not statements that these tables exist.

| Record | Owns | Must not own |
| --- | --- | --- |
| `life_domains` | id, user, name, sort, accent key from the existing palette, archived_at | Goal rows. Archiving does not delete children. |
| `goals` | id, user, domain id, title, description, type (short, medium, long, recurring, open), priority, start, optional end, status, notes, optional `cadence` (week, month, year, custom) when type is recurring, optional `target_value` and `current_value` (numbers, no currency) | Money amounts and currency. INR stays on the budget objective. For a recurring goal, `current_value` and `target_value` mirror the open period. They are not a second history. |
| `goal_periods` | id, goal id, `period_key` (for example `2026` or `2026-11`), start, end, `target_value`, `current_value`, status (open, completed, missed, skipped), completed_at | A copy of the parent goal. Closing a period does not delete it and does not pay `goal:{id}:done`. |
| `goal_milestones` | id, goal id, title, sort, status (not started, in progress, done, dropped), optional date, optional `target_value` and `current_value`, optional predecessor milestone id | Habit completion rows. |
| `projects` | id, user, title, status, notes, optional goal id, optional milestone id | A second copy of tasks. |
| `project_tasks` | id, project id, title, optional parent task id (one level), optional date, done_at | XP. |
| `goal_links` | goal or milestone id, kind (`habit`, `book`, `movie`, `budget_objective`), target id | The target's own fields. A link is a pointer. |
| `quests` | id, user, title, `quest_key` unique per user, window (day, week, month), `window_key`, status (proposed, active, done, expired, dismissed), source kind and source id | A second quest for the same source and window. A completion flag that disagrees with the source. |
| `xp_events` | id, user, `logical_key`, `source_ref` unique per user, generation, kind, amount (from the rules, signed), created_at, optional `reversal_of` | A mutable balance. Deletes. A second open award for the same `logical_key`. |
| `progression_rules` | one row per kind: amount, and whether it can reverse | Per-screen copies of the amounts. |
| `user_progression` | cached level and lifetime sum, rebuildable by replaying non-reversed events | An independently editable XP number. |
| `achievements` | definition: key, category, rarity, rule, optional XP amount | Per-user state. |
| `user_achievements` | user, achievement id, unlocked_at | A row that disappears when a streak drops. |
| `seasons` | name, start, planned end, status (active, paused, completed, abandoned) | Any field that resets XP. |
| `season_items` | season id, kind, target id | Copies of those targets. |

Lifetime XP is the sum of every `xp_events.amount`. Awards are positive. A reversal is a new row whose amount is the negative of the award it points at. Level is `threshold` applied to that sum. The cache on `user_progression` is rewritten in the same transaction as the insert. If the cache and the sum ever disagree, the sum wins and the cache is rebuilt. Nothing edits the cache by itself.

## 3. How the ledger stays safe

The ledger is append-only. It is not part of snapshot reconcile-delete. Unique scope for `source_ref` is **per user**: two people may carry the same string; one person may not. The same rule applies to `quest_key` and to `request_id`.

### Names

| Name | Meaning | Example |
| --- | --- | --- |
| `logical_key` | The real-world fact. Stable. | `habit:{habitId}:2026-11-16` |
| `source_ref` | One row. Unique per user. Includes the generation. | `habit:{habitId}:2026-11-16#1` |
| Reversal ref | One row that cancels exactly one award. | `reversal:habit:{habitId}:2026-11-16#1` |
| `quest_key` | One quest for one source and one window. | `habit:{habitId}:day:2026-11-16` |

An award is **open** when no reversal row points at it. At most one award for a `logical_key` is open.

### Guarantees

- **One open award.** Completing a fact inserts the next generation only when no open award exists for that `logical_key`. A second request, from the same phone or another, returns the open row and writes nothing. Note `already_recorded`.
- **One reversal per award.** `reversal_of` is unique per user. A second undo returns the existing reversal.
- **Reverse, then complete again.** Allowed. The first award stays in the table with its reversal (net zero). The new completion inserts generation `#2` and pays again. It does not reuse `#1`.
- **Amounts.** Read from `progression_rules`. The caller cannot pass 8 or 40.
- **Duplicates across devices.** `UNIQUE (user_id, source_ref)` and the “one open award” check run on the server, inside one transaction. Two offline phones that both complete the same habit converge on one open award when they sync. `UNIQUE (user_id, request_id)` on the command log makes a retry of the same request return the first result even before the ledger is read.
- **Snapshot.** A push of habits must not be able to omit XP rows and delete them. After the habit fact itself is saved, the progression service runs `ensure(fact)`: completed and no open award → next generation; not completed and an open award → one reversal; otherwise no-op. That is how undo and redo stay aligned with the source. The habit row may still be last-write-wins per id. The ledger follows the fact. It is not last-write-wins.

Worked habit, Monday 16 November 2026:

1. Complete. Insert `#1` amount +8. Cache adds 8. Quest `habit:{id}:day:2026-11-16` becomes done.
2. Other device, different `request_id`, same fact. Open award exists. Return `#1`. Cache unchanged. Quest stays done.
3. Unmark. Insert the reversal, amount −8. Cache adds −8. The window is still today, so the quest returns to active. If the window had already ended, the quest would be expired, not left done.
4. Unmark again. The reversal already exists. Return it.
5. Complete again the same day. Insert `#2` amount +8. Quest returns to done. Net for the day is +8, not +16.

Milestone, project, goal, custom quest, and achievement use the same generation and reversal rules. Their `logical_key` values are `milestone:{id}:done`, `project:{id}:done`, `goal:{id}:done`, `quest:{id}:done`, `achievement:{id}`. A proxy quest never has its own award, so undo of the habit does not also reverse a quest award. Closing a recurring period does not write `goal:{id}:done`.

Double-pay rules, same as the UX doc:

- A quest whose source is a habit or a task does not get its own award. The habit or the task event is the award. The quest row only changes status.
- A project named by a milestone's payment rule does not get a project award when the milestone pays.
- Goal completion pays `goal:{id}:done` once, on top of milestone awards, at the goal amount. It is not the sum of the milestones.

## 4. One completion across screens

| User action | Record that changes | XP source_ref |
| --- | --- | --- |
| Check a habit on Home, in Habit, in the planner, or via Grok | `HabitCompletionLocal` for that habit and day, then the derived log | `habit:{id}:{date}#n` once while open |
| Check a quest that points at that habit | Same habit completion. Quest status becomes done. | The habit ref only |
| Check a task | `project_tasks.done_at` | None, until the project or milestone rule pays |
| Check a quest that points at that task | Same task. Quest status becomes done. | None from the quest if the task is the source |
| Mark a milestone done | Milestone status | `milestone:{id}:done` |
| Mark a goal done | Goal status. Not implied by the last milestone. The UI asks. | `goal:{id}:done` when the user confirms |

Prayer marks stay on `DailyPrayerLogLocal`. They are not in this table.

## 5. Sync, before any of this is stored in the cloud

Today's sync is a full snapshot, last write wins, with the guards described in `RUHH_DATABASE_DESIGN.md`. That is acceptable for the current tracker entities only if the known bugs are understood:

- Habit `schedule_month_days` and `schedule_start_date_key` are sent and dropped, because they are not columns.
- Category-limit month, rollover, and category id are sent and dropped.
- Wallets, categories, periods, and standing salary never upload except in the file backup.

A later implementation phase should fix those drops in their own migration, with a backfill story, before a new phone is expected to restore a habit's monthly schedule. That fix is not Phase 1 and not Gate A.

Progression data should not join that snapshot until both of these are true:

1. Gate A has an owner-approved outcome.
2. The ledger write path in section 3 exists, separate from omission-delete.

Until then, the design assumes a future local store that can hold the new records offline, and a future sync that treats `xp_events` and `user_achievements` as append-only. Conflict rule for goals and tasks can remain last-write-wins **per id** once they have `updated_at`, which is a smaller hazard than last-write-wins of an entire XP history. Two phones editing the same goal title can still clobber. The design does not pretend otherwise. The ledger must not clobber.

## 6. Links, not merges

| From | To | Nature |
| --- | --- | --- |
| Financial Growth milestone | `ObjectiveLocal` / `budget_objectives` | Optional pointer. Budget code keeps computing the money. |
| Knowledge goal | `BookLocal` | Optional pointer. Logging the book does not move the goal. |
| Any goal | `MovieLocal` | Same, rare, still no XP. |
| Goal or milestone | `HabitLocal` | Supporting. Streak stays on the habit. Goal fraction ignores it. |
| Quest | habit, task, or milestone | Source pointer. Completing either side completes both. |
| Season item | goal, habit, or project id | Membership. Removing membership deletes nothing else. |

## 7. Gate A — plan only, not executed

Decision 9. Nothing in this section was run against production ref `gmmfimwumtbneynsyimz`. The owner could not confirm whether `origin/feature/security-session-agent` was ever applied there. Phase 0 also did not query that project. The git facts below are from the repository only, rechecked for Phase 0 and unchanged as a plan input.

### What the repo already shows

Merge-base of `main` and `origin/feature/security-session-agent` is `2eb2bc78`.

`main` is 4 commits ahead of that base, including books (`e695f74f`), movie categories (`bdc37f65`), and the 1.0.34 release (`71cd0553`).

The branch is 14 commits ahead of that base. It adds, among other things, server sessions, an agent inbox, proposal approvals, and these migration files that are **not** on `main`:

- `20261022120000_security_sessions_s1.sql`
- `20261022130000_agent_inbox.sql`
- `20261022140000_agent_api.sql`
- `20261022150000_agent_proposals.sql`
- `20261022160000_security_maintenance.sql`
- `20261022170000_legacy_mitigations.sql`

`supabase/pending/S2_retire_legacy_auth.sql` on that branch is intentionally not a migration. The branch's `ruhh/docs/SECURITY_ROLLOUT.md` says the work was not applied to production. That sentence is the branch's claim. It is not a live check.

`main` still authenticates sync with the PIN hash. `ruhh_fetch_auth_profile` returns the hash and salt. That is the exposure Gate A has to judge. See `RUHH_DATABASE_DESIGN.md`.

### Steps to run later, each with an explicit owner gate

1. **Diff, locally.** List commits on each side of the merge-base. List migration filenames on each side. Confirm the branch does not contain the books and movie-category migrations, and `main` does not contain the session migrations. No network required. This can be repeated any time from git.
2. **Read the branch's security notes** (`SECURITY_ROLLOUT.md`, `LEGACY_MITIGATIONS.md`, `AGENT_INTEGRATION.md` on that branch) against the current `main` RPCs. Produce a short memo: what v2 sessions change, what v1 still allows until S2, what breaks if S2 runs before every installed app is updated.
3. **Read-only production inspection, only after a separate approval.** Suggested check, not performed now: list applied migration versions on the project and compare them to `ruhh/supabase/migrations/` on `main` and to the six filenames above. Read-only. No `db push`, no link of this working copy onto production, no `wipe_all_user_data.sql`, no secret pasted into the repo or into chat. If the owner wants this, they approve the command and the target in writing first.
4. **Recommend one strategy** in a short note:
   - stay on v1 and accept the hash exposure for existing tables only, with new data kept on-device until a later auth, or
   - rebase the session work onto current `main`, ship the app that can speak v2, then retire v1 (S2) only after the adoption criteria in the branch's own docs, or
   - another option the inspection makes obvious.
   State data-loss and old-app consequences for the chosen option.
5. **Stop for approval.** No migration and no deploy until that note is accepted.

Gate A does not include building goals or XP. It is the door in front of Phase 2.

## 8. Rollback shape, for whenever a migration is eventually written

Not written now. When it is:

- Additive tables only at first. No rename of `habits`, `prayer_logs`, or `budget_objectives`.
- A down migration that drops only the new tables, after a backup.
- Ledger tables are not dropped as part of an app rollback if that would destroy history. Restoring a backup is the rollback for a bad ledger deploy.
- Color columns, if any new record stores a color int, are `bigint` from the first migration. `20260922110000_color_value_bigint.sql` already had to widen habit and objective colors.
