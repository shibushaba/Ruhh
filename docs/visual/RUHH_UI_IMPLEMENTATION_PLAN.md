# UI implementation plan

**Status:** a plan for after visual approval. This run does not start it.
**Direction:** The Lit Desk, in `RUHH_VISUAL_DIRECTION.md`.
**Not included:** SQL, migrations, Supabase, auth or sessions, the XP ledger, Grok’s network client, production, Gate A, merging `feature/security-session-agent`.

## Order

1. Tokens and the dock, so every later screen inherits the lit desk instead of the outlined card.
2. Home and My Journey, reading real records where they exist and an explicit empty state where they do not.
3. Goal, domains, planner, Ask, achievements, season, create, My Space, behind view-models. New progression screens render the empty state in production until their backend exists.
4. Habit, then Prayer, then Budget, then Movie and Book. One module at a time. Product rules do not change with the paint.

## View-models

Production providers return only what the app can already prove, or an empty snapshot.

```dart
class JourneySnapshot {
  const JourneySnapshot.empty() : level = null, lifetimeXp = 0, events = const [];
  final int? level;
  final int lifetimeXp;
  final List<JourneyEvent> events;
}
```

A `JourneyFixture` with the sample (level 8, the business goal, Monday 16 November 2026) lives under `ruhh/test/` and is the only input to golden tests. It is not registered in `ProviderScope` for a normal launch. Home must not invent XP, goals, or achievements to look like the PNG.

Habits, prayer marks, and budget figures that already exist in Isar may show on Home immediately. A path stone appears only when a real milestone exists.

## Files

### Shared language

| File | Change |
| --- | --- |
| `ruhh/lib/core/theme/ruhh_tokens.dart` | Add plate, tile, dock, and pill radii, the two ambient colours, and the softer shadow. Keep the existing fields so current screens do not break in the same step. |
| `ruhh/lib/core/theme/ruhh_theme.dart` | Map the new tokens into `ThemeData`. Dark stays the default. |
| `ruhh/lib/core/theme/portfolio_palette.dart` | Add the canvas step `#070708` and the ambient stops. Do not replace module hues. |
| `ruhh/lib/core/theme/nb_colors.dart` | Unchanged source of module colour. |
| `ruhh/lib/core/widgets/nb_scaffold.dart` | Background becomes the lit canvas and the masked grid, not a full-strength grid under every control. |
| `ruhh/lib/core/widgets/nb_card.dart` | Stops being the default container for new screens. Existing call sites can stay until their module is restyled. |
| `ruhh/lib/core/widgets/ruhh_components.dart` | Dock, pill, and text-button styles used by new screens. |

New, all under `ruhh/lib/features/journey/widgets/` unless a piece is shared immediately:

- `level_medal.dart`
- `path_plate.dart` (CustomPainter)
- `now_block.dart`
- `goal_spark.dart` and `measure_ring.dart`
- `domain_mosaic.dart`
- `proposal_letter.dart`
- `emblem.dart`
- `room_scene.dart` (CustomPainter; no 3D package, no `flutter_svg` unless a later review prefers an asset)
- `lit_dock.dart` if the shell dock should not live inside `home_shell.dart`

### Home and navigation

| File | Change |
| --- | --- |
| `ruhh/lib/features/home/home_shell.dart` | Six destinations become the capsule dock. Same routes. |
| `ruhh/lib/features/home/home_page.dart` | Replace the feed of cards with medal, path or empty line, Now, two goal treatments, shortcuts. |
| `ruhh/lib/features/home/widgets/home_feed_insights.dart` | Retire from the new Home or reduce to one quiet line. Do not stack it under the path. |
| `ruhh/lib/features/home/widgets/home_insight_widgets.dart` | Same. |
| `ruhh/lib/core/routing/app_router.dart` | Routes for journey, goal, domains, planner, ask, achievements, season, create, space. Each route’s builder takes a snapshot, not a hard-coded sample. |

### Later modules, when their turn comes

- Habit: `ruhh/lib/features/habit/` (today list and `habit_form_page.dart` only as far as the new type and spine).
- Prayer: `ruhh/lib/features/prayer/`. No new score widget.
- Budget: `ruhh/lib/features/budget/` home and list. Not the calculation files.
- Movie: `ruhh/lib/features/movie/`. Book: `ruhh/lib/features/book/`.

Do not restyle `features/island/`, `features/focus/`, or `features/todo/`. They stay unrouted.

## Tests and devices

- Golden tests in `ruhh/test/goldens/`, fed by the fixture, for Home, Journey, Goal, and Domains, dark and light. A second golden for Home empty.
- `MediaQuery.disableAnimations` wraps the reduced-motion golden for the path (fully drawn, no pulse).
- Semantics: dock labels, “You are here,” Confirm.
- Layout: a 390-wide golden and a check that at 600 the column caps near 560. No separate tablet design in the first pass.
- Performance: the path painter is behind a `RepaintBoundary`. No perpetual animation when the route is covered. Target a mid-range Android phone: one short draw on entry, then static.
- Dependencies: none added for this workstream. Icons stay on the Phosphor fonts already in `ruhh/assets/fonts/`.

## Done, for the first implementation PR

Home and Journey match the approved frames in dark and light, using real habit and prayer data when present, and the empty path when no goal exists. The dock is the six current destinations. Golden tests pass. No schema, no auth change, no Grok client, no XP writer.
