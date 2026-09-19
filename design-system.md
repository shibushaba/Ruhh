# RUHH — Unified Soft Mobile UI Design System

**Source note:** This specification targets three reference mobile component boards described as (1) fitness/dashboard cards, (2) onboarding/education flows, and (3) shipping/tracking flows, treated as one visual language. If the reference PNGs were not attached at extraction time, re-validate every token against those images before implementation.

**Design family:** Modern soft UI — white cards on a cool gray canvas, pastel accent fills, minimal or no strokes, diffused elevation, generous radius, pill CTAs, icon-in-tinted-chip patterns.

---

## 1. Color Palette

### Surfaces & text

| Token | Hex | Usage |
|--------|-----|--------|
| `color.canvas` | `#F4F5F9` | Full-screen page background behind all cards |
| `color.surface.primary` | `#FFFFFF` | Default card, sheet, search bar, nav bar fill |
| `color.surface.secondary` | `#FAFBFD` | Nested rows inside cards, subtle inset areas |
| `color.text.primary` | `#151822` | Titles, primary labels, stat numbers |
| `color.text.secondary` | `#8B93A7` | Captions, axis labels, helper copy, placeholders |
| `color.text.tertiary` | `#B4BAC8` | Disabled hints, calendar out-of-month days |
| `color.divider` | `#ECEEF4` | 1px hairlines inside lists (when used); not on card outlines |
| `color.overlay.scrim` | `#151822` @ 45% opacity | Modal/sheet backdrop |

Cards read as **pure white** on the canvas; no visible warm tint on surfaces.

### Accent palette

Accents appear as **both** soft pastel chip backgrounds (~15–25% visual weight of saturated hue) **and** saturated solid fills for progress bars, chart strokes, selected pills, and primary CTAs.

| Token | Hex (solid) | Pastel chip (~12% mix on white) | Typical use |
|--------|-------------|----------------------------------|-------------|
| `accent.mint` | `#22C55E` | `#DCFCE7` | Steps progress, success check row, “completed” timeline, positive deltas |
| `accent.coral` | `#F43F5E` | `#FFE4E6` | Heart rate / alert tags, destructive text sparingly, warm chart point |
| `accent.amber` | `#F59E0B` | `#FEF3C7` | Streaks, star ratings, promo/discount banners |
| `accent.sky` | `#0EA5E9` | `#E0F2FE` | Sleep charts, link actions, info chips |
| `accent.lavender` | `#8B5CF6` | `#EDE9FE` | Secondary CTAs, category chips, radial sleep dial track |
| `accent.peach` | `#FB923C` | `#FFEDD5` | Distance bar highlight, warm highlights on charts |
| `accent.slate` | `#64748B` | `#F1F5F9` | Neutral device/status rows, inactive step icons |

**Primary CTA fill:** `accent.mint` solid `#22C55E` with white label `#FFFFFF`.  
**Secondary CTA fill:** `color.surface.primary` with `color.text.primary` text and optional `color.divider` hairline.

---

## 2. Corner Radius

| Element | Radius (px) | Notes |
|---------|-------------|--------|
| Large cards (stats, charts, hero) | `24` | Consistent across dashboard tiles |
| Medium list cards (device, comment, route) | `20` | Slightly softer than grid cards |
| Primary / secondary buttons (pill) | `999` | Full stadium/pill shape |
| Small chips & tags | `12` | Category, reward point, filter pills |
| Date-picker day cell (unselected) | `12` | Square-ish rounded rect |
| Date-picker selected day | `14` | Filled pill behind numeral |
| Calendar “today” large cell | `18` | Image 3 week strip |
| Avatar containers | `999` | Circular |
| Avatar rank badge overlay | `8` | Small rounded square on corner |
| Input fields & search bar | `16` | Single continuous rounded rect |
| Segmented icon row container | `20` | Outer capsule wrapping 4 icons |
| Segmented icon inner button | `14` | Each icon hit area |
| Bottom navigation floating bar | `28` | Outer floating pill; not full-width square |
| Bottom nav active tab highlight | `16` | Soft gray pill behind active icon |
| Radial progress dial outer | `999` | Circle |
| Modal / bottom sheet top corners | `28` | When sheets appear |

**Not used:** 0px sharp corners; neo-brutal hard offsets.

---

## 3. Elevation & Shadow Style

- **Shadow type:** Soft, blurred, low-contrast — **never** hard offset neo-brutal blocks.
- **Card shadow (default):** `0 8px 24px rgba(21, 24, 34, 0.08)` — downward, slight spread.
- **Floating nav / FAB cluster:** `0 12px 32px rgba(21, 24, 34, 0.12)`.
- **Pressed card (optional micro-interaction):** reduce to `0 4px 12px rgba(21, 24, 34, 0.06)`.
- **Direction:** Primarily **down** (Y positive); negligible X offset (`0` or `2px` max).
- **Borders:** **No** thick outer borders on cards. Separation is shadow + white on gray. Internal list dividers may use `color.divider` 1px only.
- **Hero gradient card:** Subtle inner glow optional; outer edge still soft shadow, no stroke.

---

## 4. Spacing & Layout

| Token | Value (px) | Application |
|--------|------------|-------------|
| `space.screen.horizontal` | `20` | Left/right margin from screen edge to content |
| `space.screen.top` | `16` | Below status bar / below app bar |
| `space.card.padding` | `20` | Internal padding on large cards (all sides) |
| `space.card.padding.compact` | `16` | Smaller rows, list-in-card |
| `space.stack.gap` | `16` | Vertical gap between stacked full-width cards |
| `space.grid.gap` | `12` | Gap in 2-column masonry / uneven grid (image 1) |
| `space.section.titleToContent` | `12` | Section label to first card |
| `space.inline.gap` | `8` | Icon to label, chip spacing |
| `space.list.row.vertical` | `14` | Vertical padding inside list rows |

**Layout patterns:**
- **Image 1 (fitness):** Mixed **single column** plus **2-column masonry** of unequal-height cards; not a strict uniform grid.
- **Image 2 (onboarding):** Single column centered content; hero top, forms below.
- **Image 3 (shipping):** Single column with occasional **horizontal strips** (dates, step tracker, toggle chips).

**Max content width:** Full bleed mobile (~390 logical px); no desktop multi-column.

---

## 5. Typography

**Font character:** Rounded geometric sans (closest match: **SF Pro Rounded**, **Nunito Sans**, or **Plus Jakarta Sans**). Friendly, not condensed.

| Role | Size (px) | Weight | Line height | Color |
|------|-----------|--------|-------------|--------|
| Screen title | `28` | 700 | 34 | `text.primary` |
| Card title | `18` | 700 | 24 | `text.primary` |
| Section label | `15` | 600 | 20 | `text.primary` |
| Body | `15` | 400 | 22 | `text.primary` |
| Caption / meta | `13` | 400 | 18 | `text.secondary` |
| Micro label (axis, badge) | `11` | 600 | 14 | `text.secondary` |
| **Stat display (hero number)** | `32` | 700 | 38 | `text.primary` |
| **Stat display (large)** | `26` | 700 | 32 | `text.primary` |
| **Stat display (medium)** | `20` | 600 | 26 | `text.primary` |
| Currency / duration inline | `18` | 600 | 24 | `text.primary` |

**Numeric emphasis:** Stats (`3620`, `6 hrs 59 mins`, `$150.00`) use **heavier weight and 1.2–1.6× size** vs adjacent labels; labels stay `text.secondary` at caption size.

**Letter-spacing:** Default; tab labels in bottom nav `0.2px` tracking optional.

---

## 6. Iconography

### Functional UI icons
- **Style:** Outlined / line icons, **not** filled (except checkmarks in success states).
- **Stroke:** ~`1.75px` effective at 24dp; rounded caps and joins.
- **Size:** `24` default; `20` in chips; `28` in nav active state.
- **Color:** `text.primary` on white; on pastel chips use matching **solid accent** (e.g. mint icon on `#DCFCE7` chip).

### Icon chip pattern (very common)
- **Container:** Circle `40×40` or rounded square `40×40` @ `12px` radius.
- **Fill:** Pastel accent from Section 1 (semantic: sleep → sky, steps → mint, etc.).
- **Icon:** Centered, solid accent color, no chip border.

### Illustration / mascots (image 2)
- **Separate from UI icons:** Full-color or flat illustrative characters (avatars in onboarding, leaderboard).
- **Detail level:** Multi-shape illustration with facial features; used in hero and leaderboard — **not** reused at 24dp toolbar size.

---

## 7. Component Inventory

Each entry: **anatomy**, **accent(s)**, **radius**.

### 7.1 Stat + horizontal progress card (“Steps”, image 1)
- **Anatomy:** Top row — small label (`text.secondary`) + optional trailing icon chip; middle — large stat (`32/700`) with optional “/ target” smaller; bottom — full-width horizontal progress track (`6px` height, radius `999`) with mint fill.
- **Accent:** `accent.mint` bar; chip may be mint pastel.
- **Radius:** Card `24`.

### 7.2 Line / area chart card (“Sleep details”, image 1)
- **Anatomy:** Title row; chart area with smooth area fill (sky @ 25% opacity) and sky stroke; X-axis weekday labels (`micro`); floating callout pill on active point with value + date.
- **Accent:** `accent.sky` stroke/fill; callout white with shadow.
- **Radius:** Card `24`; callout `12`.

### 7.3 Vertical bar chart card (distance, image 1)
- **Anatomy:** Title; row of vertical bars with one **selected** bar taller/highlighted; draggable callout bubble above selected bar showing numeric value; baseline labels.
- **Accent:** Default bars `accent.slate` @ 30%; selected `accent.peach` solid.
- **Radius:** Card `24`; bars top `6`.

### 7.4 Horizontal date-picker strip (images 1 & 3)
- **Anatomy:** Scrollable row of day cells: weekday abbr + date numeral; one **selected** cell with solid dark or mint fill and inverted text; others white/transparent on canvas.
- **Accent:** Selected `text.primary` fill `#151822` or `accent.mint`.
- **Radius:** Cell `12`; selected `14`.

### 7.5 Device connection card (“OnePlus Watch”, image 1)
- **Anatomy:** Left product image (watch render); right column title + status dot row (connected green) + text link “Connect” / “Manage”.
- **Accent:** Status dot `accent.mint`; link `accent.sky`.
- **Radius:** Card `20`.

### 7.6 Horizontal avatar leaderboard row (“Friends”, image 1–2)
- **Anatomy:** Scroll row of avatars `48` circular; optional rank badge `#1` `#2` on corner `8px` radius; name below optional.
- **Accent:** Rank badges amber/mint/coral pastel fills.
- **Radius:** Avatar `999`; badge `8`.

### 7.7 Radial progress dial (“Average Total Sleep”, image 1)
- **Anatomy:** Large circle track (lavender pastel); progress arc (lavender solid); center label primary stat + caption below.
- **Accent:** `accent.lavender` track + arc.
- **Radius:** Outer `999`; no square corners.

### 7.8 Floating pill bottom navigation (all images)
- **Anatomy:** White floating pill inset from screen bottom `16px`; 4–5 **icon-only** tabs; active tab gray pill `16` behind icon; no labels or tiny labels below per variant.
- **Accent:** Active icon `text.primary`; inactive `text.tertiary`.
- **Radius:** Bar `28`; active highlight `16`.

### 7.9 Gradient hero card + CTAs (image 2)
- **Anatomy:** Full-width card with **diagonal gradient** (`accent.lavender` → `accent.sky`); headline `28/700` white; subtext white @ 85%; primary pill “Get started” white fill dark text OR white text on dark pill; row of social auth pills (white, logo + label).
- **Accent:** Gradient hero; social pills white `999`.
- **Radius:** Hero `24`; buttons `999`.

### 7.10 Stepped onboarding progress (image 2)
- **Anatomy:** Horizontal line connecting numbered circles; completed steps filled mint with white check; current step mint border; future steps gray border empty.
- **Accent:** `accent.mint` completed; `color.divider` line.
- **Radius:** Circles `999`.

### 7.11 Radio selectable list item (“Class category”, image 2)
- **Anatomy:** Full-width row: leading icon chip; title + subtitle; trailing radio ring (selected = mint fill dot).
- **Accent:** Chip pastel per category; selected radio `accent.mint`.
- **Radius:** Row container `16` when grouped in card; chip `12`.

### 7.12 Segmented icon-button row (image 2)
- **Anatomy:** Outer capsule `20`; 4 equal icon buttons; selected segment white inner shadow + darker icon.
- **Accent:** Container `#F4F5F9`; selected surface `#FFFFFF`.
- **Radius:** Outer `20`; inner `14`.

### 7.13 Comment / question card (image 2)
- **Anatomy:** Header row avatar + name + timestamp; body text; small reward tag pill (“+10 pts”); footer text link “Reply”.
- **Accent:** Tag `accent.amber` pastel; link `accent.sky`.
- **Radius:** Card `20`; tag `12`.

### 7.14 Search bar + result card (image 2)
- **Anatomy:** Rounded search field with leading magnifier; trailing clear `×`; below, result card with title, meta, chevron.
- **Accent:** Focus ring none; clear icon `text.secondary`.
- **Radius:** Search `16`; result card `20`.

### 7.15 Vertical shipment timeline (“Tracking Shipping”, image 3)
- **Anatomy:** Left vertical line with nodes; each node icon in circle; right column title + date; **current** step highlighted mint background row; past steps muted check; future hollow.
- **Accent:** Current `accent.mint` pastel row; completed icons mint.
- **Radius:** Node circles `999`; row highlight `12`.

### 7.16 Tracking number input + scan (image 3)
- **Anatomy:** Single-line input `16` radius; trailing square scan button with camera/barcode icon (mint or dark fill).
- **Accent:** Scan button `text.primary` or `accent.mint`.
- **Radius:** Input `16`; scan btn `14`.

### 7.17 Horizontal icon-label step tracker (image 3)
- **Anatomy:** 4 steps in a row: icon + label below; connector lines; states: done (mint check circle), active (filled), upcoming (outline).
- **Accent:** Done/active `accent.mint`.
- **Radius:** Step icon `999`.

### 7.18 Toggle / switch chip group (“Flash / Gallery / Switch”, image 3)
- **Anatomy:** Segmented pills in one row; selected dark fill white text; unselected white gray text.
- **Accent:** Selected `#151822`; unselected `color.surface.primary`.
- **Radius:** Group `14`; segments inherit.

### 7.19 From / to route card + swap (image 3)
- **Anatomy:** Two stacked location rows (dot + label + address); centered swap circular button overlapping divider.
- **Accent:** Origin dot mint; destination dot coral; swap btn white + shadow.
- **Radius:** Card `20`; swap `999`.

### 7.20 Cost breakdown list + total (image 3)
- **Anatomy:** Rows label left amount right; final **Total** row bold larger on tinted background `#F4F5F9`.
- **Accent:** Total amount `text.primary` only.
- **Radius:** Card `20`; total inset `12`.

### 7.21 Calendar week strip with large “today” (image 3)
- **Anatomy:** 7 columns; **today** cell enlarged width, mint pastel fill, bold date numeral; other days minimal.
- **Accent:** Today `accent.mint` pastel.
- **Radius:** Today cell `18`; others `12`.

### 7.22 Discount / promo banner (image 3)
- **Anatomy:** Horizontal banner: left illustration or icon; right headline + condition text; optional “Apply” link.
- **Accent:** Banner bg `accent.amber` pastel; CTA `accent.mint` text link.
- **Radius:** `16`.

### 7.23 Additional components observed in the set
- **Metric twin-card row:** Two equal cards side-by-side (`grid.gap 12`) with single stat each — radius `20`.
- **Notification bell / profile avatar** header: circular `36` avatar top-right; no border.
- **List row chevron:** Standard disclosure `›` `text.tertiary` for navigation rows.
- **Empty chart placeholder:** Dashed `divider` baseline only, caption centered.

---

## 8. Buttons

| Variant | Fill | Text | Height | Radius | Shadow |
|---------|------|------|--------|--------|--------|
| **Primary pill CTA** | `#22C55E` | `#FFFFFF` 15/600 | `52` | `999` | `0 8px 20px rgba(34,197,94,0.35)` optional |
| **Secondary pill** | `#FFFFFF` | `#151822` | `48` | `999` | card shadow |
| **Secondary outline (rare)** | transparent | `#151822` | `48` | `999` | none; 1px `#ECEEF4` |
| **Tonal / dark pill** | `#151822` | `#FFFFFF` | `44` | `999` | soft |
| **Social auth pill** | `#FFFFFF` | `#151822` | `48` | `999` | card shadow; leading brand glyph |
| **Text link button** | none | `accent.sky` 15/600 | auto | — | none |
| **Small icon circle** | `#FFFFFF` or pastel chip | icon | `40` | `999` | light shadow |
| **Destructive text** | none | `accent.coral` | auto | — | none |

**Icon-only circular:** `44×44`, white fill, soft shadow, icon `24` centered — used for swap, scan, filter.

---

## 9. What NOT to Do

Consistent across all three reference boards — **do not reintroduce:**

| Avoid | Why |
|--------|-----|
| Thick black 2–3px borders on cards | References use shadow separation, not neo-brutal strokes |
| Hard offset shadows (4px 4px 0 blur 0) | Conflicts with soft elevated card language |
| Fully saturated neon backgrounds on full cards | Accents stay chips, bars, arcs, or CTAs |
| Dense multi-paragraph blocks | Copy is short labels + one stat or one chart focal point |
| Overlapping card stacks | Cards stack vertically with clear gaps; no z-fighting collage |
| Sharp 0px corners on primary components | Radius 12–24px is mandatory |
| Mixed icon styles (filled + outline in same toolbar) | Keep functional icons outline-only |
| More than one primary CTA color fighting per screen | Mint green owns primary action |
| Low-contrast gray-on-gray body text | Secondary text still meets ~4.5:1 on white |

**Do maintain:** generous whitespace, one clear focal element per card, pastel semantic color coding, pill shapes for primary actions, floating bottom nav with soft shadow.

---

## Implementation token map (quick reference)

```yaml
# Copy into Flutter ThemeExtension / design tokens later
canvas: "#F4F5F9"
surface: "#FFFFFF"
textPrimary: "#151822"
textSecondary: "#8B93A7"
radiusCard: 24
radiusButton: 999
radiusChip: 12
shadowCard: "0 8px 24px rgba(21,24,34,0.08)"
accentMint: "#22C55E"
accentCoral: "#F43F5E"
accentAmber: "#F59E0B"
accentSky: "#0EA5E9"
accentLavender: "#8B5CF6"
accentPeach: "#FB923C"
```

---

*End of design-system.md — review against source reference PNGs, then proceed to UI rebuild prompts.*
