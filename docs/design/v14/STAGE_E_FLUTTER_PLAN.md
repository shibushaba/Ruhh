# Stage E — Flutter implementation plan

**Status:** plan only. No widgets, routes, fonts, or Isar fields are added in this change.
**Approved design:** `docs/design/v14/` (v14, Shabas). The earlier Lit Desk frames in `docs/visual/` are superseded for the UI by v14. Product rules from Phase 1 still hold.
**Does not authorize:** SQL, migrations, Supabase, auth or session changes, an XP writer, Grok deployment, production, Gate A, or merging `feature/security-session-agent`.

Prayer, Movies, Books, and Budget still award no XP. INR appears only on Money.

## 1. What Stage E builds

Replace the six-icon bottom shell with the living scene and the Ruu orb, and restyle the existing modules into the v14 inner layouts. New progression places (quests, goals, planner, journey, chat) get routes and empty states. They do not get a backend.

The shell today is `StatefulShellRoute.indexedStack` in `ruhh/lib/core/routing/app_router.dart`, painted by `ruhh/lib/features/home/home_shell.dart`. Stage E replaces that indexed stack with one `ShellRoute`. Auth, splash, and onboarding stay on the root navigator (`/splash`, `/auth/welcome`, `/auth/login`, `/auth/signup`, `/onboarding`, `/onboarding/notifications`).

## 2. Theme tokens

Add a `V14Colors` (or a new `ThemeExtension`) without deleting the current desk tokens until each module has moved. v14 is dark only. The existing light theme stays available for screens that have not been restyled, so a light-mode user is not stranded mid-migration. Do not invent a light v14 in this stage. `DESIGN_SYSTEM_V14.md` dropped light on purpose.

| Token | Hex | Use |
| --- | --- | --- |
| base | `#0E0F10` | Screen ground, scrims, pin fill |
| surface | `#16181A` | Panels, tiles, every world's panel tint |
| raised | `#1F2225` | Selected cards, secondary button |
| hairline | `#2A2E32` | Dividers, inactive tracks |
| line-strong | `#3A3F44` | Connectors, empty arcs |
| text | `#F4EEDC` | Primary, warm off-white |
| muted | `#B3B0A9` | Secondary |
| dim | `#8F9194` | Tertiary, off |
| missed | `#7F9A96` | Missed or rested marks. Never red, never an error colour |
| jade | `#3FC08A` | Primary button, XP, level ring |
| amber | `#F2A93B` | Streaks |
| lavender | `#B9A6F2` | Prayer only. Not a score |
| gold | `#E8C26A` | Relics and the level-up accent. Not a surface |

World and pet accents stay data on the theme pack (`DESIGN_SYSTEM_V14.md`, `PETS_V14.md`). Chrome does not pick up those hues as backgrounds. Decoration stays at level B: one motif per component, a 1px accent outline near 40% opacity, glow only on progress and the single hero action.

## 3. Fonts and licensing

`google_fonts` is already in `ruhh/pubspec.yaml` (`^6.2.1`). Do not fetch fonts at runtime. The app is offline-first. Set `GoogleFonts.config.allowRuntimeFetching = false` and ship the files under `ruhh/assets/fonts/v14/`, or load them with `fontFamily` from the asset bundle and skip the package at runtime. The package may stay for the existing theme until that theme is removed.

| Role | Family | Notes |
| --- | --- | --- |
| Titles and numbers | Mochiy Pop One | Display, level, day numeral |
| Body and labels | Zen Maru Gothic | UI copy |
| Companion lines | Kiwi Maru | Speech bubble only |
| Malayalam and rupee | Noto Sans Malayalam | `fontFamilyFallback`. U+20B9 (₹) is not in the three display families |
| Arabic | Noto Naskh Arabic | Fallback for Arabic script |

All five are SIL Open Font License 1.1. Commit the OFL text beside the files. Subset to the scripts the app actually shows (Latin, Malayalam, Arabic, the rupee sign) so the binary stays small. Do not subset away ₹.

The sample copy says the call name "Shabas". Production uses the signed-in username, or a call name stored on the local profile. Do not hardcode a person's name in a widget.

## 4. Navigation

`V14Shell` wraps the `ShellRoute` child.

- On `/home` the shell draws the world, the hotspot pins, the chips, and the 64px Ruu orb (bottom centre). There is no tab bar.
- On every other shell route it draws a 48px mini orb. Tap goes to `/home`. Hold, or the tap-tap path, opens the ring.
- The ring is an overlay, not a route. Six nodes, radius about 160, hit targets 52–60px: Home, Prayer, Money, Habits & Quests, Books, Movies. Hold the orb and slide to a node. Sliding past a node opens an outer arc of three sub-pages (Money → This month / Add spend / Categories, as in `dragon-w2-ring-sub-money.jpg`).
- Tap alternative: tap the orb, then tap a node. Tap outside or system back closes the ring.
- A peek card on the ring shows that node's live numbers from existing providers (budget total, habit count, prayer marks). It does not invent XP.
- List mode (`dragon-w2-list-mode.jpg`) is the same destinations as 56px rows. It turns on with a screen reader and from Settings → Navigation. A "Places" rotor lists them. A left-hand option mirrors the orb.
- First-run demo (`dragon-w2-first-run-demo.jpg`) is three steps: hold or tap, with Skip and Try it. Completion is a local flag, not a server field.
- Labels chip forces every pin caption on. Default is one hero pill (the next habit) plus icon, arc, and count on the others. Pins are a 34px mark inside a 44px target.

Reduced motion: the ring appears in place, room changes are crossfades, glows are static, no particles.

## 5. Route map

Existing pages stay. The shell stops being six branches. Sub-routes that push a form (`add`, `edit`, `detail`) use the root navigator, as they do now, and still show a way home.

| v14 place | Route today | Stage E |
| --- | --- | --- |
| Living-scene Home | `/home` | Scene for the active world. Pins open the modules below. `/analytics` is not a ring node. Leave it on the router, linked from Settings, until someone decides to drop it |
| Habits orbit | `/habit`, `/habit/new`, `/habit/edit/:id`, `/habit/detail/:id` | Orbit layout over the same `HabitPage` data. Forms stay |
| Quests board | none | New `/quests`. Empty state until the quest model exists. A switch on the orbit can select it |
| Goal climb | none | New `/goals` and `/goals/:id`. Empty state. The climb is the layout, not a new goal table |
| Money blocks | `/budget`, `/budget/add`, `/budget/edit/:id` | Treemap of existing categories for the month, INR. Sub-ring opens this month, add, categories. Calculations stay in the budget feature |
| Planner dial | none | New `/planner`. Reads today's habits and prayer marks. Does not create quests |
| Prayer sky | `/prayer`, `/prayer/stats` | Arc of the five prayers. Lavender. Copy says it is not scored. No streak, no XP |
| Books shelf | `/book`, `/book/add`, `/book/edit/:remoteId` | Shelf. Logging a book still awards nothing |
| Movies | `/movie` and its add, edit, categories, detail routes | Stubs in the same Night nook, second segment. No XP |
| Journey | none | New `/journey`. Chapter title on Home opens it. Relics and Season are chips on that page, empty until those records exist |
| Chat | none | New `/chat`. Ruu's bubble opens it. The transcript is local-only UI state for this stage. No Grok client, no network write |
| Settings | `/settings`, `/settings/notifications`, `/settings/overlay` | Bento tiles. Add Navigation (list mode, left hand) and the pet row (read-only once chosen) |
| Level-up, morning, evening | none | Overlays, not routes. Morning 07:00 and evening 21:00 are local notifications that deep-link home. They do not grant XP. W3's big bell and the bubble can open the same sheets |

Hotspots per world are in `STRUCTURE_V14.md`. Panda and Cat use the same actions with the positions in `PETS_V14.md`. Positions are data (`Alignment` or fractions of the scene), not magic offsets inside each widget.

## 6. Inner layouts

Each is one screen with the mini orb. None of them is a column of identical cards.

- **Habits orbit.** Stones (or the pet's equivalent) around a centre. Hold 0.6s lights a habit, or tap Light it. Undo for 5 seconds. Completing still calls the existing habit repository. The `+8` in the renders is sample copy. The widget shows XP only if a future engine returns an amount. Until then the line is the habit name and the streak the app already stores.
- **Quests board.** Notes on a wall. Pluck or tap Done. Empty copy when there are no quests. No generated quests in this stage.
- **Goal climb.** A vertical path of beads. Hold a bead or tap and confirm. Empty climb when there are no goals.
- **Money blocks.** A treemap of this month's spending by category, INR, from the existing budget aggregates. Blocks can be jade, amber, dim, and sky as category colour, not as a life score. The header says it never earns XP.
- **Planner dial.** A day ring. Drag a stop, or tap Move. Sources are scheduled habits and prayer times. Undo 5 seconds.
- **Prayer sky.** An arc. Marks use the existing daily log. Missed or rested uses `#7F9A96`, not red. No XP and no streak.
- **Books and movies.** One Night nook, two segments. Shelf for books, poster stubs for movies. Both say they award no XP.
- **Settings tiles.** Groups, not a long outlined list. The renders use a bento. Notification and overlay routes stay.

## 7. Pets, worlds, and level

Three packs, one code path. `petId` selects a bundle: five scene images, world names, form names, accent tables, a motif painter, an orb portrait crop, and a line pack. Navigation, data, and XP rules do not fork per pet.

| Pet | id | Default name | Motif |
| --- | --- | --- | --- |
| Dragon | `dragon` | Ruu | Per world: ember, leaf, maple, wind, star |
| Panda | `panda` | Sumi, user may rename | Ensō |
| Cat | `cat` | Kage, user may rename | Slit-eye diamond |

Picker, try, and confirm match `PETS_V14.md`. Try themes a sample home for 45 seconds and writes nothing. Confirm requires the checkbox. The line on that screen is "Saved on this device in your profile."

**Storage now:** a later edit to `UserLocal` in `ruhh/lib/core/data/models/user_local.dart` (`petId`, optional `petName`, `petChosenAt`). Isar only. No Supabase column. The field is written once. The UI treats it as read-only after that. This plan does not add the field.

**Data decision still open:** whether backup or a new phone keeps the pet, whether "reset everything" may reopen the picker, and whether support can change it. Do not sync `petId` until that decision exists.

**Worlds.** Five worlds. v14 labels them with level bands 1–24, 25–44, 45–64, 65–84, 85–100. Those bands are a presentation map, not a new curve.

**Sub-stages.** Four per world, each a quarter of that world's band. The dragon names in the doc are the ends of the span (Ember Egg → Hearthling, and the paired names in worlds 2–4). Intermediate quarters reuse the nearest drawn form until art exists. Selection is `formFor(level)`, not a switch inside the scene widget.

**Curve.** Level comes from a `LevelCurve` interface. The only approved implementation is the Phase 1 curve, `floor(50 * (level - 1) ^ 1.55)`, lifetime XP, no daily cap. XP curve v2 is not approved and must not be coded as the default. `WorldMap` takes a level from that interface, so a future curve swaps in one place. If the long curve leaves people in world 1 for a long time, that is acceptable until the map is retuned. Do not compress the curve to fill five worlds.

Until an XP ledger exists, level is null. Home shows world 1 and does not pretend a level. The sample "Lv 33" is fixture data for goldens only.

## 8. Art pipeline

Scenes are full-bleed backgrounds. Ship the smallest JPEG that is sharp at the device pixel width (about 1170px wide for a 390pt phone at 3x). Target under 250KB a scene. Portrait crops for the orb come from the same file, not a second download.

Dragon worlds 1–5 are in the renders. Panda and Cat have worlds 1 and 5 only. `PETS_V14.md` says worlds 2–4 for those pets are not drawn. The pack falls back to a dim charcoal scene with the right accents rather than stretching the wrong world, and the picker does not offer a pet whose required worlds are missing unless the fallback is explicit in the UI ("art still coming" is not a silent substitution of the dragon).

Chrome (orb, ring, pins, type) is Flutter, not baked into the JPEG, so one background serves every locale.

**Rive is an open decision.** Default is CustomPainter for the ring, pins, and motifs, plus the JPEG scene. That keeps a Rive runtime off mid-range Android. Revisit Rive only for the orb and the level-up moment if a spike stays inside the frame budget below. Do not block Stage E on that spike.

## 9. Accessibility

- 44px minimum targets. Pins, ring nodes, chips, orb, and mini orb all meet it. The visible pin art may be 34px inside the target.
- Every gesture has a tap path: hold-slide or tap-tap, hold-to-light or Light it, pluck or Done, drag or Move, pinch-back or mini orb or system back.
- Every log action shows Undo for 5 seconds and calls the existing repository undo where one exists. Where the action is not built yet, the control is disabled rather than a fake undo.
- Reduced motion as in section 4.
- List mode and the Places rotor.
- Left-hand orb.
- Labels chip.
- Missed is `#7F9A96`, never red, and the word "missed" or "rested" is present so colour is not the only signal.
- Screen-reader names on the orb ("Ruu, open places"), each pin, and each ring node.

## 10. Performance budget

- One scene decode, width-capped, in `ImageCache`. Do not decode all 15 worlds at launch.
- The ring is a widget overlay. It is not a second full-screen image.
- `RepaintBoundary` around the scene. The orb's glow does not repaint the JPEG.
- No perpetual animation. A ring fan runs once on open and stops. Reduced motion skips it.
- Home, after the scene is cached, should not drop frames on a mid-range Android phone (target the class of a 4GB device from a few years ago). Cold start may spend one frame decoding a single JPEG.
- Do not add a particle system, a 3D package, or Rive in the first milestone.

## 11. Milestones

Each milestone is a later PR. None of them is this document.

| # | Ships | Accepted when |
| --- | --- | --- |
| E1 | Tokens, bundled fonts, ₹ fallback, dark v14 extension. Old theme still builds | A widget test paints jade, missed, and a Mochiy title. A string with ₹ uses the fallback and does not show a box |
| E2 | `ShellRoute`, orb, tap-tap ring, list mode, first-run demo. Home can be a static dragon W2 scene behind the chrome | The six current modules open from the ring and from list mode. TalkBack reaches them. No tab bar on `/home` |
| E3 | Living home: pins from data, one hero pill, moon chip, chapter title, level ring. Dragon scenes 1–5 | With no goals, no fake path. With real habits, the focused pin is the next due habit. Labels chip matches `dragon-w3-home-labels.jpg` behaviour |
| E4 | Habits orbit, money blocks, prayer sky, night nook, settings tiles, wired to current repositories | Prayer and money goldens show no XP. Money shows INR. A habit check still hits the existing completion API. Undo lasts 5 seconds |
| E5 | Empty routes: quests, goal climb, planner dial, journey, chat | Each opens, explains that it is empty, and does not write XP or call a network client |
| E6 | Pet picker, try (no write), confirm, `UserLocal.petId` write-once, rename | Second launch does not show the picker. Try writes nothing. Panda and Cat do not pretend worlds 2–4 exist. This milestone is the one that touches Isar, and only after the pet data decision in section 7 is accepted or explicitly deferred with the local-only flag |
| E7 | Goldens and a reduced-motion pass | See section 12 |

E6 is the only milestone that changes a local model, and it waits on the data note. It still does not add a Supabase column.

## 12. Tests

- Widget tests for the ring: hold-slide and tap-tap both select Money; tap outside closes; a node announces its name.
- Widget tests for pins: 44px target, hero pill is the only caption when Labels is off.
- Widget tests that prayer copy and money copy do not contain an XP award, and that a movie or book save is not passed an XP callback.
- Golden tests under `ruhh/test/goldens/v14/`, dark, fed by a fixture that is not registered in `ProviderScope`. Minimum set: dragon homes W1–W5, ring evolution, money sub-ring, habits orbit, goal climb empty and fixture, money blocks, prayer sky, pet picker, pet confirm, list mode.
- One golden with `MediaQuery.disableAnimations` (ring already open, no fan).
- Fixture level numbers are allowed inside `ruhh/test/`. Production providers return null level and empty lists for objects that do not exist yet.
- Do not golden-test a network chat.

## 13. Risks

- The 1–100 world bands and the approved long curve disagree. People may stay in Ember Nest. The map is data so it can move without a rewrite. Do not "fix" this by changing the curve.
- Hotspots are hand-placed per world and per pet. New art means new coordinates. Keep them in one table.
- The ring is easier to miss than tabs. The demo, the hint, the orb, and list mode are the mitigation. A five-person "find Books" check is still worth doing before calling E2 done.
- Pins are small on bright art (Wind Temple). The 44px target matters more than the drawn circle.
- Replacing `StatefulShellRoute.indexedStack` drops the free keep-alive of six tabs. Keep the habit and budget providers alive above the shell so a visit to Money does not reload the month.
- Chat must not grow a Grok client inside a UI milestone.
- Pet permanence conflicts with reinstall and with backup until the data decision exists. Local-only is the temporary rule, and the confirm screen should say "on this device".
- Missing Panda and Cat worlds. Do not ship a broken theme as if it were complete.

## 14. Open decisions

1. Pet sync, backup, reset, and support override. Local-only until then.
2. Whether the world bands stay 1–24 … 85–100 once the long curve is in use, or get retuned. The curve itself stays.
3. Rive versus CustomPainter for the orb and level-up.
4. Names and art for the two middle sub-stages of each world. Quartiles and nearest form until then.
5. Panda and Cat worlds 2–4 art.
6. Whether `/analytics` stays in Settings or is removed.
7. Whether morning and evening sheets are notifications, in-app only, or both.
8. Call-name field versus using the username only.
9. Light theme: v14 does not include one. Whether the old light theme is removed after the shell ships is a later call.
10. XP curve v2 and any daily cap. Not approved. Not part of Stage E.
