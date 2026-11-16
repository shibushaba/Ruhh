# RUHH owner decision log

**Owner:** Shabas
**Date locked:** 16 November 2026
**Applies to:** Phase 1 design. Implementation is not approved.
**Source:** the owner's review of the Phase 0 audit. This file is the binding record. Where an earlier Phase 0 proposal disagrees with a row here, this file wins.

Phase 1 used these decisions and did not reopen them. Items marked **later** are intentionally not designed as open product choices.

| # | Decision | What Phase 1 did with it |
| --- | --- | --- |
| 1 | Keep the shipped dark desk: grid, DM Sans, Outfit, existing colours, square controls, near-square cards. Reject root `design-system.md`. The new experience must feel more alive: progression, XP feedback, timelines, milestone drawing, subtle motion. Not a generic dashboard. Not a copy of Life Reset. | Frames in `docs/designs/` use those tokens. Motion is specified as short and removable. No character, no gold coins, no 66-day ring. |
| 2 | Screen title and nav destination stay **Home**. **My Journey** is the progression experience inside Home, with its own weight. Home and the journey stay distinct. | Home frame has the title Home and a My Journey card. A separate My Journey detail is a pushed screen, not a seventh tab. |
| 3 | Six destinations only: Home, Budget, Habit, Prayer, Movie, Book. Goals, milestones, domains, projects, and quests are reached from Home and related screens. | Every frame keeps that bar. New screens use a back control to Home or My Journey. |
| 4 | Eight default domains, user-configurable: add, rename, reorder, archive, without losing history. | Domain screen and the domain rules in `RUHH_UX_ARCHITECTURE.md`. Archive hides a domain from Home and keeps its past goals. |
| 5 | Prayer is outside the XP engine. No XP by default. No negative XP. No score of spiritual worth. Do not reuse the old prayer-points code. No prayer XP toggle in the initial design. | No prayer award in the XP table. Prayer appears on Home and the planner as a log, labeled not part of XP. Achievements do not auto-score salah. |
| 6 | Island, Focus, and Todos stay unrouted. Island coins are not XP. Do not delete Focus or Todo code. Focus may be evaluated later as a utility. Todos may later be considered for migration into projects. Do not revive unfinished screens just because they exist. | Architecture lists them as out of the product surface. No frame shows the island. |
| 7 | Movies and books stay independent libraries. They may be linked to a learning goal as resources. Adding one does not move a domain score and does not award XP. | Goal links are references. The XP table has no media award. |
| 8 | Budget objectives stay financial. A Financial Growth goal or milestone may link one. Models are not merged. Budget math stays independent of progression. | The revenue milestone points at an objective. It does not become one. Transactions award nothing. |
| 9 | Auth is untouched in Phase 1. Do not extend PIN-hash RPCs to new tables without a security decision. The owner cannot confirm that `feature/security-session-agent` was never applied to production. Before Phase 2, plan Gate A and do not execute production steps. | Gate A is written in `RUHH_DATA_BOUNDARIES.md` as a plan. It was not run. No production inspection. |
| 10 | Design Grok now. Implement later. Grok is core. It uses RUHH's authenticated services, never its own database writer, and never computes XP. Start with reads and structured proposals. Consequential writes wait for confirmation. The agent branch is only a candidate after the security and rebase review. | `RUHH_GROK_INTEGRATION.md` is the contract. It does not adopt the branch's operations as-is. |
| 11 | INR only inside Budget. Progression is currency-free. A financial goal may optionally link an INR objective. | No rupee amounts on journey, XP, or domains. The link is named on the goal frame. |
| 12 | Phase 1 is documentation, diagrams, workflows, and static UI only. No Flutter prototype, Dart, SQL, migrations, or production changes. The owner reviews the experience visually before implementation. | This branch is docs, HTML/CSS frames, and PNGs. |

## Additional requirements, also binding

| # | Requirement | Where it is specified |
| --- | --- | --- |
| A1 | Lifetime progression. Levels, achievements, lifetime XP, and history do not reset when a season ends. | UX architecture, season frame, journey frame. |
| A2 | XP ledger is reliable: one source-event reference per award, idempotent, reversible, and not deletable by snapshot reconciliation. | UX architecture XP section and `RUHH_DATA_BOUNDARIES.md`. |
| A3 | One completion. Habit, quest, task, and milestone resolve to the same underlying record. No duplicate completion and no duplicate XP. | UX architecture, "One write" section. Grok contract uses the same keys. |
| A4 | Quests come from real goals, habits, tasks, and milestones. No manufactured chores. | Quest lifecycle. Planner frame. |
| A5 | Goal progress is milestone progress or an explicit target. No invented life score. One habit never auto-completes a goal. | Goal workflow. Goal frame. |
| A6 | Review full-snapshot, last-write-wins sync before any new progression data. Protect the XP ledger on its own. | `RUHH_DATA_BOUNDARIES.md`. |
| A7 | Personal, not strict task management. A break and a return do not punish. | Journey gap, copy rules, no negative XP. |

## What was superseded from the Phase 0 proposal

The Phase 0 roadmap suggested optional prayer XP, default off. Decision 5 removes that. There is no toggle in this design.

The Phase 0 roadmap suggested designing Grok in a later phase. Decision 10 pulls the contract into Phase 1 and leaves the build for after the domain services and Gate A.

## Refinements after the first Phase 1 review

**Date:** 16 November 2026, second pass. The direction stands. These rows are what changed before Phase 1 is offered as complete. Still no app code, no SQL, no Gate A, no Phase 2.

| # | Refinement | Where it landed |
| --- | --- | --- |
| R1 | Keep the desk. Give progression more personality: a level seal, a milestone stepper with "you are here", stamps that separate Habit, Quest, Project, and Goal, and Home actions for New goal and Domains. Motion is specified, including reduced motion. Not a new theme. | Frames, `docs/designs/MOTION.md` |
| R2 | Design the missing journeys, not only the desk: create goal, edit milestones, create project, custom quest, goal-completion confirm, undo. | `RUHH_WORKFLOWS.md` and the matching frames |
| R3 | A recurring goal has separate periods. Each period has its own progress and completion history. Measurable goals and milestones carry `current_value` and `target_value`. The UI uses the same fields. | `RUHH_UX_ARCHITECTURE.md`, `RUHH_DATA_BOUNDARIES.md`, `measure-*.png` |
| R4 | A generated quest's identity is source plus window, unique per user. One daily habit produces one quest for that date. Undoing the source puts the quest back in agreement with it. | UX architecture, data boundaries, `undo-*.png` |
| R5 | Ledger: `source_ref` unique per user, one open award, one reversal per award, a new generation if the fact is completed again, cache is the sum of signed amounts, duplicate requests across devices return the existing row. Append-only, outside snapshot delete. | `RUHH_DATA_BOUNDARIES.md` |
| R6 | Amounts 8 / 6 / 40 / 60 / 24 stay provisional. A simulation of four usage profiles is published for 30 days, 90 days, 1 year, and 2 years. Levels 7–11 are titled **Finding your rhythm**. Other titles stay provisional. | `RUHH_XP_BALANCE.md`, `docs/tools/xp_level_sim.py` |
| R7 | The sample day is Monday 16 November 2026. | Planner frame and the other frames that name "today" |
| R8 | Grok's primary surface is in-app. The contract stays independent of that surface so another channel can be added later. Confirmation rules and the service boundary are unchanged. | `RUHH_GROK_INTEGRATION.md`, `grok-*.png` |

## Still open, and not blockers for reading this design

1. **The other title words, and whether the provisional amounts should change after reading the simulation.** Levels 7–11 are decided. The integers are still the ones to build from unless you mark different ones. The rules around them stay locked.
2. **Todos.** Whether they later become project tasks is an evaluation, not a Phase 1 decision. Focus stays a later utility evaluation. Neither is in the frames.

## Visual overhaul, 16 November 2026

The owner reviewed the refined Phase 1 frames. Architecture stands. The visuals do not: too flat, too many identical outlined cards, too much text of the same weight.

| # | Direction | What it changes |
| --- | --- | --- |
| V1 | Identity stays: palette, DM Sans, Outfit, dark-first, the grid as a motif, six destinations. The square-control and near-square-card rule is no longer binding where a different shape makes the screen clearer. | `docs/visual/RUHH_VISUAL_DIRECTION.md` |
| V2 | Two studies before a lock. **A Ambient** is type, air, and one arc. **B My Space** is a room that changes only for real progress. | `a-*.png`, `b-*.png` |
| V3 | Recommended direction is **The Lit Desk**: Ambient’s hierarchy, plus one pictured object, the lit path. My Space is a place you open, not the chrome of every screen. Objects that do not match a real goal are not drawn. | Unprefixed frames in `docs/visual/png/` |
| V4 | A UI implementation branch is authorized only after these frames are approved. It starts with tokens, the dock, Home, and My Journey. It uses real data or an explicit empty state. Sample XP stays in tests. | `docs/visual/RUHH_UI_IMPLEMENTATION_PLAN.md` |
| V5 | That UI branch does not authorize SQL, Supabase, auth, the XP backend, Grok deployment, production, Gate A, or merging the security-agent branch. | Same plan |

## Explicitly not decided, because Phase 2 is not approved

Schema SQL, auth replacement, merging `feature/security-session-agent`, production reads, and any Flutter work. The visual frames are waiting for approval before the UI branch starts.
