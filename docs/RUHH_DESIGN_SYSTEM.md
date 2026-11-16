# RUHH design system (Phase 0 audit)

**Phase 1 note:** the new frames in `docs/designs/` use this system. They add a journey card, a milestone rail, and a level moment without changing tokens in the app. Light frames draw a faint ink hairline because `borderHighlight` (white at 55%) does not separate a white card from the desk. That hairline is picture-only.

**Date:** 16 November 2026
**What this file describes:** the visual system that actually ships in `ruhh/lib`, version 1.0.34.
**What it does not describe as current:** the root file `design-system.md`. That document specifies a different product (soft gray canvas `#F4F5F9`, 24px cards, pill radius 999, blurred shadows, "no neo-brutal hard offsets"). The running app does not use those tokens. Keep `design-system.md` as a rejected or unused exploration. Do not implement it over the shipped UI.

The app's own comment names the source of the shipped palette: portfolio tokens from shabas.vercel.app (`ruhh/lib/core/theme/portfolio_palette.dart`, `ruhh/lib/core/theme/ruhh_tokens.dart`).

READMEs at the repo root and in `ruhh/` still say "neo-brutal". Class names still start with `NB`. The pixels are a near-square portfolio desk: hairline highlight borders, a 22px grid, and a hard sticker shadow, not the 4px offset blocks exported by the unused `UI/` package (`neuOffset = Offset(4, 4)`, `neuBorder = 3`).

## 1. Color

Tokens are `RuhhTokens.light` and `RuhhTokens.dark`, installed as a `ThemeExtension` by `RuhhTheme` (`ruhh/lib/core/theme/ruhh_theme.dart`). Read them with `context.ruhh`.

### Surfaces

| Token | Light | Dark | Defined in |
| --- | --- | --- | --- |
| Canvas | `#EBEBEB` (`deskLight`) | `#050505` (`deskDark`) | `portfolio_palette.dart` |
| Surface | `#FFFFFF` (`paperLight`) | `#141414` (`card`) | same |
| Surface secondary | `#F0F0F0` | `#1F1F1F` (`secondary`) | `ruhh_tokens.dart` / palette |
| Text primary | `#0A0A0A` (`inkLight`) | `#F5F5F5` (`foreground`) | palette |
| Text secondary | `#5C5C5C` | `#949494` (`mutedForeground`) | tokens / palette |
| Text tertiary | `#949494` | `#6B6B6B` | `ruhh_tokens.dart` |
| Divider | `#383838` | `#383838` (`border`) | tokens / palette |
| Card border | `#FFFFFF` at 55% (`borderHighlight` `0x8CFFFFFF`) | same | palette |

`NBColors` (`nb_colors.dart`) still has parallel helpers (`canvas`, `surfaceFill`, `mutedText`) that match the desk colors. New work should prefer `context.ruhh` so the two sets do not drift further.

### Module identity

Used on home cards, onboarding tiles, and insight accents (`nb_colors.dart`):

| Module | Hex |
| --- | --- |
| Budget | `#38BDF8` |
| Habit | `#4ADE80` |
| Prayer | `#A78BFA` |
| Movie | `#FB7185` |
| Book | `#FBBF24` |

### Named accents

`RuhhTokens` carries mint, coral, amber, sky, lavender, peach, and slate, each with a pastel. They are **not** the hex values in root `design-system.md`.

| | Light solid | Dark solid |
| --- | --- | --- |
| Mint | `#059669` | `#4ADE80` |
| Coral | `#E11D48` | `#FB7185` |
| Amber | `#D97706` | `#FBBF24` |
| Sky | `#0284C7` | `#38BDF8` |
| Lavender | `#7C3AED` | `#A78BFA` |
| Peach | `#EA580C` | `#FB923C` |
| Slate | `#64748B` | `#94A3B8` |

Light pastels are tints such as mint `#E8F5EE`. Dark pastels are deep mixes such as mint `#1A2E22` (full list in `RuhhTokens.dark`).

`NBMetrics` keeps a second pair for money: income `#22C55E`, expense `#EF4444`, warning `#F59E0B`. Theme `ColorScheme.error` is `#DC2626` in light and `#EF4444` in dark.

`RuhhTokens.categoryAccents` is a five-step grayscale. Budget categories also carry their own `colorValue` and emoji (`CategoryLocal`).

### The desk

`NBGlassBackground` (`nb_glass.dart`) paints the page. `PortfolioGridPainter` draws a 22px grid (`gridStep`) in `#E0E0E0` (light) or `#1F1F1F` (dark). Dark mode adds the two gradients in `PortfolioPalette` (`deskGradientDark`, `deskGradientAccentDark`). Scaffolds are transparent so the grid shows through (`scaffoldBackgroundColor: Colors.transparent`).

This grid is the closest thing the app has to a "place". It is a desk, not a living room and not a game map.

## 2. Typography

`RuhhTheme` applies **DM Sans** to the text theme and **Outfit** to button and chip labels (`GoogleFonts.dmSansTextTheme()`, `GoogleFonts.outfit()`). Phosphor is an icon font, not a text face (`pubspec.yaml` families `PhosphorRegular`, `PhosphorFill`, `PhosphorDuotone`).

Styles on `RuhhTokens`:

| Role | Size | Weight | Line height |
| --- | --- | --- | --- |
| Screen title | 32 | 800 | 38 |
| Card title | 18 | 700 | 24 |
| Stat hero | 32 | 700 | 38 |
| Stat large | 26 | 700 | 32 |
| Stat medium | 20 | 600 | 26 |
| Body (`bodyLarge`) | 15 | 400 | 22 |
| Caption | 13 | 400 | 18 |
| Micro | 11 | 600 | 14 |

Screen title adds `letterSpacing: 0.5`. Titles and stats use `textPrimary`. Caption and micro use `textSecondary`.

Home currently uses the screen-title style for the literal word "Home" (`home_page.dart`).

## 3. Spacing

From `RuhhTokens` (both brightnesses):

| Token | px |
| --- | --- |
| `spaceScreenHorizontal` | 20 |
| `spaceStackGap` | 16 |
| `spaceGridGap` | 12 |
| `spaceCardPadding` | 16 |
| `spaceCardPaddingCompact` | 12 |

`NBLayout` (`nb_layout.dart`): page padding `EdgeInsets.fromLTRB(20, 8, 20, 24)`, `sectionGap` 24, `itemGap` 12, `maxContentWidth` 720. Scroll views add bottom clearance for the floating nav (`ruhh_scroll_insets.dart`, `RuhhNavClearance`).

## 4. Radius

| Token | Value |
| --- | --- |
| `radiusCardLarge`, `radiusCardMedium` | `2` (`PortfolioPalette.radiusSm`) |
| `radiusInput` | `3` (`radiusMd`) |
| `radiusButton`, `radiusChip`, `radiusNavBar`, `radiusNavActive` | `0` |
| `NBMetrics.radius` | `0` |

Buttons, chips, and the bottom nav are square. Cards are barely rounded. This is the identity. A Phase 1 mock that uses 24px cards and pills will look like a different app.

## 5. Elevation and borders

| Shadow | Definition |
| --- | --- |
| `shadowPaper` (cards) | color `#000000` at 70% (`0xB3000000`), offset `(0, 8)`, blur 40 |
| `shadowSticker` (nav, primary button) | color `#000000` at 50% (`0x80000000`), offset `(2, 4)`, blur **0** |

`cardDecoration` on `RuhhTokens`: surface fill, radius 2, **1px** `borderHighlight`, paper shadow. `NBMetrics.borderWidth` is 1 and `shadowOffset` is zero; some older `NB*` widgets follow that instead of the sticker shadow. Both exist. New surfaces should use `cardDecoration` so the border treatment stays consistent.

## 6. Cards and components

Shared widgets live in `ruhh/lib/core/widgets/`. Feature code should reuse these before adding another card.

| Widget | File | Role |
| --- | --- | --- |
| `RuhhSoftCard` | `ruhh_components.dart` | The named card. Despite "soft", it uses the square portfolio decoration. |
| `RuhhStatProgressCard` | same | Label, hero number, progress. |
| `RuhhTwinMetricRow` | same | The Home "Today" pair. |
| `RuhhRadialDial` | same | Circular progress. Habit tracker also has `animated_radial_dial.dart`. |
| `RuhhLineChartCard`, `RuhhBarChartCard` | same | Lightweight chart cards. Budget trends also use `fl_chart`. |
| `RuhhInsightRow`, `RuhhTimelineRow` | same | Row patterns. Timeline is visual only; there is no journey model behind it. |
| `RuhhStepProgress` | same | Stepped dots. |
| `RuhhGradientHero` | same | Gradient header block. Use sparingly; the desk is mostly flat. |
| `RuhhPrimaryButton`, `RuhhSecondaryButton`, `RuhhIconCircleButton` | same | Actions. |
| `RuhhSegmentedChips`, `RuhhSegmentedIconRow`, `RuhhModuleTabStrip` | same | In-module tabs (Budget, Habit, Prayer, Movie, Book). |
| `RuhhFloatingNav`, `RuhhNavDestination` | same | The six-icon bar. |
| `RuhhScreenHeader`, `RuhhProfileAvatar`, `RuhhEmptyChartPlaceholder`, `RuhhRankBadge`, `RuhhSelectableRow` | same | Header, avatar, empty chart, small badge, select row. |
| `NBCard`, `NBButton`, `NBTextField`, `NBPinInput`, `NBTile`, `NBStatCard`, `NBDialog`, `NBModuleScaffold`, `NBPageBody`, `NBEmptyState`, `NBSection`, `NBChip`, `NBProgressBar` | `nb_*.dart` | The older named layer. Still used widely (auth PIN, forms, module scaffolds). |
| `NBGlassBackground`, `NBGlassSurface`, `NBGlassPanel` | `nb_glass.dart` | Desk and panels. |

Module-local widgets worth keeping: habit tiles, heatmap cell, and goal stepper (`habit_tracker_widgets.dart`); prayer day tiles (`prayer_tracker_widgets.dart`); budget ledger rows, pie, amount keypad (`features/budget/widgets/`).

`UI/` (`neubrutalism_ui`) is not part of this system. It is a path dependency with zero imports from `ruhh/lib`.

## 7. Navigation

`HomeShell` pins `RuhhFloatingNav` to the bottom, full width, over the page. Six destinations, **icon only**, Phosphor regular when idle and Phosphor fill when selected (`home_shell.dart`). Selection animates with `AnimatedPositioned`, about 220 ms (`ruhh_components.dart`). The bar radius is 0, the border is the highlight stroke, and the shadow is `shadowSticker`.

Active module screens use `NBModuleScaffold`: transparent app bar, title, optional FAB (plus icon), and `RuhhModuleTabStrip` for the inner tabs.

There is no drawer and no labeled tab bar.

## 8. Icons

Bundled Phosphor fonts, mapped in `ruhh/lib/core/icons/app_icons.dart` (the comment says this avoids a broken package). Nav, bell, and the add FAB use `AppIcons`.

Material `Icons.*` is still common in budget, prayer, habit appearance, and the overlay. The set is mixed. A later pass can standardize on Phosphor; it should not block the product architecture.

Habit icons are a named catalog with emoji fallbacks (`habit_appearance.dart`), including `fitness`. They are per-habit, not a domain icon system.

## 9. Motion

| Mechanism | Where it is used |
| --- | --- |
| `StaggeredEntranceColumn` (`list_entrance.dart`, package `flutter_staggered_animations`) | Home feed |
| `CelebrationBurst` (`celebration_burst.dart`, package `confetti`) | Habit tracker widgets, prayer tracker widgets. Also imported by the unused `home_redesign_sections.dart`. |
| `animated_radial_dial.dart` / `animated_count_up.dart` | Habit tracker |
| `pressable_scale.dart`, `page_transitions.dart`, `ruhh_async_button.dart` | Shared motion helpers |
| `RefreshIndicator` on Home | Mint accent |

`shimmer_placeholders.dart` is not imported. `flutter_animate` and `lottie` are in `pubspec.yaml` and unused in `ruhh/lib`. No reduced-motion switch was found. New celebration (level-up, achievement) should go through one helper and respect a future reduced-motion flag, rather than adding another dependency.

## 10. Light and dark

Both themes exist and are complete token sets. `main.dart` selects `ThemeMode.dark` or `ThemeMode.light` from `settings.darkMode`. The default in `SettingsController.build` is `darkMode: true`, and the first launch writes that default (`settings_controller.dart`). The overlay entry forces the dark theme (`main.dart` `overlayMain`).

Any new screen has to be checked in both brightnesses. The dark desk is the product's default face.

## 11. My Space, as it exists today

It does not exist as a named surface.

What users see:

- A dark (or light) gridded desk.
- A screen titled Home.
- A greeting, two today-scores, insight cards, and module highlights.
- Square white or near-black cards with a hairline border.
- Module color used as a small accent, not as a full-bleed theme.
- An icon nav that is always there.

The unrouted island screen is a shop of emoji pieces bought with coins. It is a different visual idea (a toy map) and it is not reachable. Treating it as My Space would surface unfinished code and a second currency. The recommendation in the roadmap is to evolve Home, on this desk, and leave the island alone until the owner asks for it.

## 12. Rules for later UI work

- Use `RuhhTokens` and the widgets in section 6.
- Keep radius 0 on controls and 2 on cards unless the owner explicitly changes the identity.
- Keep the grid. Do not cover it with a second full-screen background.
- One accent per card, taken from the module or from `accentMint` for a primary action. Do not introduce a new rainbow for levels.
- Progress is a bar, a dial, or a count the user can explain. Not a blended life percentage.
- Motion is short and optional in spirit: the screen must still make sense if the confetti never plays.
- Empty states already have `NBEmptyState`. Use it. Do not invent shame copy ("you failed today's quest").
- Do not restyle the app onto root `design-system.md`.

## 13. Gaps relative to the vision

The component kit can already draw a stat, a dial, a timeline row, a step progress, and a celebration. It cannot yet express a level, an XP history line, a domain, a milestone, or a quest, because those models do not exist. Phase 1 should specify those patterns using the tokens above before anyone builds them. The likely new pieces are a journey header (level, title, a single progress bar) and a "today" list row that can represent a habit, a prayer, a task, or a quest without looking like four different products. Those are specified as proposals in `docs/RUHH_IMPLEMENTATION_ROADMAP.md`, not as widgets to add in Phase 0.
