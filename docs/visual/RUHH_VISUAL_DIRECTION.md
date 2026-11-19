# RUHH visual direction

**Status:** for approval. No Flutter yet.
**Date:** 16 November 2026
**Supersedes:** the “square controls, near-square cards” part of decision 1, where a different shape serves the screen. It does not supersede the palette, DM Sans, Outfit, dark-first, the six destinations, or any product rule (prayer outside XP, no fake progress, no life score).

The Phase 1 frames were accurate and too alike. Almost every object was an outlined rectangle with a label and a sentence. This pass treats the visual experience as its own product problem.

## What stays

- Colours from `RuhhTokens` and `PortfolioPalette`: canvas `#070708` in the frames (the shipped desk is `#050505`; the lit frames sit one step off black so the glow reads), light desk `#EBEBEB`, paper white, ink `#0A0A0A` / `#F4F4F5`.
- Module hues: mint `#4ADE80`, sky `#38BDF8`, amber `#FBBF24`, lavender `#A78BFA`, coral `#FB7185`, peach `#FB923C`. On light text, the darker token accents (`#059669`, `#0284C7`, and the rest in `RuhhTokens.light`).
- DM Sans for words. Outfit for numerals, the dock is icon-only, pills.
- Dark is the default.
- The 22px grid remains, masked so it fades out by mid-screen and does not sit on top of type.
- Home, Budget, Habit, Prayer, Movie, Book.

## Two studies

They are different compositions, not recolors. Both are dark. Both use the same palette.

### Direction A — Ambient RUHH

`docs/visual/png/a-home-dark.png`, `a-journey-dark.png`.

A premium personal OS made of type, air, and one arc. The level is a 92px numeral. Today is one sentence. Goals are two lines and a fraction. There is no illustration and almost no container. The grid is barely there. The dock is the only solid object.

This is calm and expensive. It is also close to a well-set notes app. A goal does not look like a journey. A domain would have nowhere to live except another line of type. Over a year of real life, Ambient stays elegant and starts to feel interchangeable.

### Direction B — RUHH My Space

`docs/visual/png/b-home-dark.png`, `b-journey-dark.png`.

The screen is a room. A window, a lamp, a stack of books, a plant, a line in the floor. The lamp is lit only because the business goal is in progress. The books are this year’s 3 of 12. The copy says the empty side stays empty. Journey is three stations, not a feed.

This is the one a person would recognize as RUHH from across the room. It is also a poor daily tool if the room has to carry every habit, quest, and prayer mark. Illustrated objects multiply, or the day gets hidden under the picture.

## Recommendation — The Lit Desk

Use Ambient’s hierarchy and My Space’s one signature object. Do not average them.

The operating system is type, a fading grid, a soft pool of sky and mint light, and a dock. Progression gets a single pictured thing: **the lit path**. Home shows a short arc of it, with a glow on the stone where the person actually is. A goal is that path stood up, so completed, current, and upcoming stones are obvious without a numbered card list. My Space is the room from Direction B, and it is a place you enter. Objects appear only for real goals. Relationships with nothing in it does not get a decoration.

Why this and not A or B alone:

- A solves “too many boxes” and does not solve “the journey should be visible.”
- B solves identity and will not scale to Tuesday’s list without becoming a toy.
- The Lit Desk keeps the day readable in one second (the large “Now”) and makes the lifetime something you can see (the path), while the room stays special because it is not on every screen.

Frames for the recommendation are the unprefixed files in `docs/visual/png/`, dark and light.

## Tokens for this direction

These are the values the frames use. They are proposals for `RuhhTokens`, not a code change.

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| canvas | `#070708` | `#EBEBEB` | screen |
| surface | `#141418` | `#FFFFFF` | path plate, tiles, letter, dock |
| ink | `#F4F4F5` | `#0A0A0A` | primary text, pill fill |
| muted | `#9B9BA3` | `#5C5C5C` | secondary |
| ambient | sky at 16% | sky at 12% | ellipse at the top |
| ambientMint | mint at 14% | mint at 12% | second ellipse, current-node glow |
| grid | white at 4.5% | ink at 5% | 22px, masked to the top 42% |
| radiusPlate | 28 | 28 | path, room |
| radiusTile | 22 | 22 | domain tile |
| radiusDock | 29 | 29 | navigation |
| radiusPill | 999 | 999 | the one filled action |
| shadow | `0 18px 50px rgba(0,0,0,0.38)` | `0 16px 40px rgba(20,20,20,0.08)` | plates and tiles |

No default 1px white border. A container is a surface, a shadow, and a radius, or it is not a container at all.

Type, roughly: Outfit 42–92 for the day numeral and the level; DM Sans 26 for the thing that is now; 16–20 for a goal name; 13–14 for the rest. One screen has one large line. It does not have ten headings of the same size.

## Components

| Piece | What it is | Where |
| --- | --- | --- |
| Level medal | Circle, gradient ring, number. Not a square stamp. | Home, Journey |
| Path plate | One curve, completed stone filled, current stone lit, later stones hollow. | Home, Journey, Season |
| Now | A 26px line and a ring. No card. | Home, Planner |
| Goal spark | A short stroke, used for milestone goals. | Home |
| Measure ring | A circle and a fraction, used for a counted target. Different shape from the spark on purpose. | Home |
| Spine | A vertical line and dots. Type beside it. | Goal, Planner, a proposal |
| Domain tile | Radius 22, one accent wash, one icon, a count. Wide tile for the domain that has the active focus. | Domains |
| Letter | The proposal. A surface, not a chat bubble. “Nothing is saved” is the first line. | Ask |
| Pill and text | Confirm is a pill. Not now is words. | Ask, Season, Create |
| Emblem | A small drawn mark, not a row. Locked emblems are dim, not a grey card. | Achievements |
| Room | Window, floor, and only the objects the data supports. | My Space, and Direction B |
| Dock | Six icons, capsule, shadow. Home is the active icon by colour, not by a boxed square. | Every primary screen |

Creation is a question and an underline, then chips for domain and type. It is not a form of stacked outlined fields. See `create-dark.png`.

## Motion

Specified, not animated in the PNG.

| Moment | Motion | Reduced motion |
| --- | --- | --- |
| Path first shown on a screen | Stroke draws in 600ms, once. | Path is complete immediately. |
| Current stone | A glow at mint 14%. No loop required. A 2.4s pulse is allowed only while the screen is visible. | No pulse. |
| Level changes | Numeral crossfades 200ms. | Instant. |
| Check a habit | Ring fills 180ms. | Instant. |
| Dock, tiles, prayer | No bounce, no shake, no reward burst. | Same. |
| My Space | Objects do not idle-animate. | Same. |

Nothing moves to punish a missed day.

## Empty, so the pictures do not become the product

Until a real goal exists, Home does not draw a path with placeholder stones. The medal can show a real level if lifetime XP exists; otherwise the line is “Add a goal to start a path,” and the plate is absent. My Space shows the window and the floor. The lamp, the books, and the plant are omitted until those goals exist. Achievements that are locked can show a dim emblem only when the rule is real. A fixture for golden tests may draw the sample life in this folder. That fixture is not registered in the running app.

## How the other modules pick this up

After Home and My Journey, one module at a time. Same dock, same type scale, same “one large line,” module colour used as a wash or a dot, not as a stack of bordered cards.

| Module | What changes visually | What does not |
| --- | --- | --- |
| Habit | Today becomes the Now line. The list of habits can be a spine. | Streaks, schedules, the completion record. |
| Prayer | A quiet day view. Lavender is a dot, not a score. | No ring that fills as a grade. No XP. |
| Budget | One figure (the period), then a spine of transactions. | INR, the existing math, objectives as money objects. |
| Movie, Book | Shelves as tiles or a spine, not a table of outlines. | Logging a title still awards nothing and does not move a domain by itself. |

## Accessibility and phones

- The frames are 390×844. Past about 600px wide, the content column stays near 560 and the mosaic becomes three columns. The path does not stretch edge to edge on a tablet.
- Contrast: ink on canvas and ink on surface. Muted text is secondary, not the only label of a control.
- The dock icons need names: Home, Budget, Habit, Prayer, Movie, Book. The path’s current stone has a name (“You are here, Build an MVP”).
- Targets for Confirm, Create, and the dock are at least 44px.
- Colour is never the only difference between done, current, and later. The words are there.
- Reduced motion follows the system setting.
- No new animation package. No 3D engine. The path, medal, rings, and room are drawn (CustomPainter or an SVG asset). One dependency is not required for this.

## What this does not approve

SQL, Supabase, auth, the XP service, deploying Grok, production, or merging `feature/security-session-agent`. Ask is a picture of the in-app surface. Confirm still means nothing is written until the person agrees, and Grok still does not compute XP. The implementation order is `RUHH_UI_IMPLEMENTATION_PLAN.md`.
