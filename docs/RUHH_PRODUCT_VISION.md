# RUHH product vision

**Status:** Phase 0 record of the owner's vision, still the target. Phase 1 (16 November 2026) locked the owner's decisions in `RUHH_OWNER_DECISIONS.md` and designed the experience. The app is unchanged.
**Source:** the owner's product-evolution brief (November 2026). This file restates that vision so later phases have one place to read it. It is not a claim that the current app already does these things. What the app actually does is in `docs/RUHH_ARCHITECTURE.md`.

**Audited tree:** `main` at `71cd0553` (RUHH 1.0.34). This checkout was not compared to a live database.

## What RUHH is

RUHH is a personal life operating system: a gamified self-improvement platform whose job is to help one person become who they want to be, through meaningful progress over a lifetime.

Philosophy: **build your life, one meaningful action at a time.**

It is not a 66-day challenge and it has no fixed ending. A 7-day goal, a 90-day challenge, a 1-year objective, and a 5-year ambition are all ordinary cases. Gamification supports real-world progress. It does not replace it, and it does not manufacture motivation the day the user opens the app.

## What the product should help someone do

- Understand where they stand.
- Define who they want to become.
- Turn ambitions into goals.
- Break goals into milestones and into projects (the "how").
- Build habits they can keep.
- Finish meaningful daily and weekly missions that come from their own plans.
- See physical, mental, spiritual, financial, and intellectual growth as separate stories, not one misleading percentage.
- Look back across months and years.
- Build discipline without depending on artificial rewards.

## The systems that have to fit together

These are product systems, not a mandate to rename tables. Existing modules stay; new systems attach to them. See the roadmap for the proposed boundaries.

| System | Role |
| --- | --- |
| My Journey | Profile, level, lifetime XP, current level progress, title, achievements, timeline. Levels come from meaningful actions, not from opening the app. |
| Life domains | Configurable areas. Defaults: Health & Fitness, Spirituality, Knowledge & Learning, Discipline, Career & Business, Financial Growth, Relationships, Personal Development. A domain can hold goals, milestones, projects, habits, quests, and achievements. Domain progress and overall progress are not the same number. |
| Goals and milestones | What the person is trying to become or finish. Short, medium, long, recurring, and open-ended. Several milestones, each with its own state. Completing one habit never auto-completes a goal. |
| Projects and actions | How the goal gets done. Tasks, subtasks, deadlines, notes. A project may feed a goal or stand alone. |
| Habit engine | Frequency, schedule, quantity or time, reminders, history, streak, best streak, completion rate. A missed day does not erase lifetime progress. Streaks can recover. |
| Quests | Daily, weekly, monthly, or tied to a goal or milestone. Generated from the user's real plans. Custom quests are allowed. Filler tasks are not. |
| XP, levels, rewards | One progression engine. XP only from verified events, each with a unique reference, reversible, with a history the user can read. Lifetime XP is not the same thing as a spendable currency. No XP for opening the app. No double awards. Thresholds live in one formula, not scattered constants. |
| Achievements | Named, rare or common, some automatic and some user-defined. Unlocking one does not rewrite history. |
| Seasons | Optional 30/60/90-day focus. Pausing, finishing, extending, or abandoning a season never resets lifetime XP, achievements, level, or history. |
| Daily planner | One place that shows today's habits, quests, milestones, project tasks, and the modules that already exist. Completing an item once updates every surface that shows it. |
| Existing life modules | Prayer, budget, habits, and the shelves the app already has (movies, books) stay. They are not rebuilt to make room for the new experience. Shared progression events fire only on a real, verified completion. |

## Sensitive activities

Prayer is outside the XP engine entirely for the initial design. There is no prayer XP toggle. The product must never imply that a person's spiritual worth is a number. The old prayer-points code is not reused. See decision 5 in `RUHH_OWNER_DECISIONS.md`.

## Home

Home answers four questions in a few seconds: Where am I? What matters today? What progress am I making? What is next?

It stays personal. It is not a corporate analytics dashboard. Progressive disclosure: the day first, the lifetime behind it. The owner kept the screen title **Home** and placed **My Journey** inside it. The desk grid stays. See `docs/RUHH_DESIGN_SYSTEM.md` and `docs/RUHH_UX_ARCHITECTURE.md`.

## Grok Bot

Grok is a conversational way into the same system, not a second system. The Phase 1 contract is `docs/RUHH_GROK_INTEGRATION.md`. Reads run immediately. Creates and completions are proposals until the person confirms. Prayer is not written and is not scored. Grok never computes XP and never writes the database except through RUHH's own services. Implementation waits until those services and Gate A exist.

## How the product should feel

Premium, calm, modern, slightly playful. Gamified without looking like a cartoon game. Depth without neon, without crowded cards, without glass everywhere, without motion the user cannot turn off. The identity to preserve is the one in the running app, documented in `docs/RUHH_DESIGN_SYSTEM.md`, not an unused spec.

## What this vision refuses

- A fixed-length challenge as the whole product.
- XP for trivial or unverified actions.
- One overall percentage blended from unrelated metrics.
- Shame copy when a day is missed.
- A second source of truth for a habit, a prayer, a transaction, or an XP award.
- Replacing Budget, Habit, Prayer, Movie, or Books to "make room".
- Fake sample data in production.

## Where the current app stands relative to this vision

The shipped app (1.0.34) is a personal tracker: budget, habits, prayer, movies, and books, with a home dashboard, offline storage, and optional cloud backup. It has streaks, a prayer history, and budget savings goals. It does not have life domains, lifetime goals, milestones, projects, quests, a central XP ledger, levels, seasons, or a connected Grok Bot. Those gaps are listed in `docs/RUHH_IMPLEMENTATION_ROADMAP.md`. The vision is the target. Phase 1 designed it and stopped. The app still does not contain it.
