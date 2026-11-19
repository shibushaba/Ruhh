# RUHH asset pack (v14)

Everything the Flutter build needs for the 3 companions (Ruu the dragon, Sumi the panda, Kage the cat) × 5 worlds. Original IP. No UI text is baked into any plate. `manifest.json` is the source of truth; this file explains it.

## Layout
| Folder | What | Size / format |
|---|---|---|
| `plates/{pet}/w{n}_{slug}.webp` | Home scene plates, portrait, 390×844 design frame ×2.77 | 1080×2340 WebP q82 |
| `plates_wide/{pet}/…` | Same art, full original 9:16 width (tablets / parallax overscan) | 720×1280 WebP q84 |
| `sprites/{pet}/…` | Transparent evolution-form cut-outs, feet on bottom edge (16 px pad) | WebP RGBA q90, 300–1190 px tall |
| `orbs/{pet}/w{n}.webp` | Circular companion portrait for the bottom orb, alpha outside the circle | 256×256 WebP RGBA |
| `icons/motifs/*.svg` | Motif glyphs, `currentColor` (ember, leaf, maple, wind, star, enso, slit_eye) | 24×24 viewBox |
| `icons/motifs/{pet}/w{n}_*.svg` | Same, pre-tinted with each world's accent | 24×24 |
| `icons/ui/*.svg` | UI line icons, 1.75 stroke, `currentColor` | 24×24 |
| `backdrops/dragon/*.webp` | Painted inner-screen backdrops | 1080×2340 |
| `backdrops/{panda,cat}/w{n}_inner.webp` | Blurred and dimmed world plate for every inner screen | 1080×2340 |
| `_preview/*.jpg` | QA contact sheets (hotspots drawn on plates, sprite lineups). Do not ship. | – |

Flutter: declare `assets/ruhh/` with the subfolders in pubspec. Use `flutter_svg` for SVGs (`colorFilter` for tint). Precache the current pet/world plate, orb and sprite at startup.

## Plates and hotspots
* Paint the plate with `BoxFit.cover`, aligned to the centre. The design frame is 390×844, and the plate is exactly that frame at 1080×2340, so on a 390×844 phone the plate maps 1:1.
* A hotspot's `x,y` in the manifest is normalized to the plate (0–1). To place it on screen, compute the cover transform: `scale = max(W/1080, H/2340)`, `ox = (W - 1080*scale)/2`, `oy = (H - 2340*scale)/2`, then `px = ox + x*1080*scale` and `py = oy + y*2340*scale`.
* Every pin is a 44×44 tap target centred on `x,y` (`hitSize: 44`). The label pill goes on `labelSide` (`r` or `l`). `opens` is the route. `heroPill` is the top-of-list item chip (left-anchored). `companionTap` is a rectangle that opens Chat when tapped.
* `plates_wide` coordinate conversion: `x_wide = (x*590.8 + 64.6)/720`, and `y` stays the same.
* `fixedHotspots` are shared by every world: Lv ring, chapter title, prayer moon chip, speech bubble, streak chip, orb, Labels chip. They sit on the bottom and top gradient bands, so keep a `#0E0F10` gradient (0→85%) over the top 14% and bottom 22% of every plate.

### Hotspot tables (normalized x, y)

**dragon · W1 Ember Nest** (Lv 1–24, accent `#F2A23A`) · hero (0.2, 0.4171) · companion tap 0.1538,0.2725 → 0.8462,0.5924

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | hanging lantern | goals | 0.2256 | 0.1801 | r |
| habits | candle ledge | habits | 0.1436 | 0.3815 | r |
| quests | quest wall notes | quests | 0.641 | 0.2109 | l |

**dragon · W2 Moss Ledge** (Lv 25–44, accent `#7BD389`) · hero (0.359, 0.6635) · companion tap 0.5641,0.0355 → 1.0,0.3555

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | bridge lanterns | goals | 0.1077 | 0.4953 | r |
| quests | leaf post | quests | 0.7692 | 0.391 | l |
| habits | stepping stones | habits | 0.2821 | 0.6161 | r |

**dragon · W3 Cliff Shrine** (Lv 45–64, accent `#E2A65C`) · hero (0.441, 0.3697) · companion tap 0.5897,0.2014 → 1.0,0.4739

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| habits | bell rope | habits | 0.3846 | 0.3341 | r |
| wrapup | big bell | evening | 0.0923 | 0.3104 | r |
| goals | stone lanterns | goals | 0.5282 | 0.4171 | r |
| quests | ema rack | quests | 0.0923 | 0.5355 | r |

**dragon · W4 Wind Temple** (Lv 65–84, accent `#6CC3E8`) · hero (0.1692, 0.2038) · companion tap 0.3846,0.1422 → 1.0,0.5569

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| habits | wind chimes | habits | 0.1128 | 0.1682 | r |
| goals | floating islands | goals | 0.1026 | 0.3555 | r |
| quests | banners | quests | 0.0923 | 0.5545 | r |

**dragon · W5 Star Summit** (Lv 85–100, accent `#F0C75E`) · hero (0.1436, 0.2133) · companion tap 0.2564,0.3791 → 0.8462,0.8294

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| habits | constellation | habits | 0.0872 | 0.1777 | r |
| quests | waiting lanterns | quests | 0.0923 | 0.4408 | r |
| goals | sky lanterns | goals | 0.8564 | 0.5355 | l |

**panda · W1 Bamboo Hollow** (Lv 1–24, accent `#D9C08A`) · hero (0.1897, 0.5213) · companion tap 0.2564,0.3436 → 0.7179,0.5687

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | hanging lantern | goals | 0.2256 | 0.1896 | r |
| habits | candle lamps ledge | habits | 0.1333 | 0.4858 | r |
| quests | notes on stone post | quests | 0.7231 | 0.2844 | l |

**panda · W2 Mist Terraces** (Lv 25–44, accent `#A8D5A2`) · hero (0.2872, 0.5924) · companion tap 0.5385,0.1422 → 0.9487,0.4384

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | lantern rope | goals | 0.1026 | 0.1777 | r |
| habits | stepping stones | habits | 0.2308 | 0.5569 | r |
| quests | notes on post | quests | 0.8333 | 0.5569 | l |

**panda · W3 River Gorge** (Lv 45–64, accent `#8FC9C2`) · hero (0.1026, 0.6066) · companion tap 0.4359,0.2844 → 0.7949,0.5806

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| quests | hanging plaques | quests | 0.1026 | 0.4265 | r |
| habits | river stepping stones | habits | 0.1795 | 0.5569 | r |
| goals | stone lanterns | goals | 0.8462 | 0.5569 | l |

**panda · W4 Plum Cloud** (Lv 65–84, accent `#E3A9C4`) · hero (0.1333, 0.2133) · companion tap 0.3333,0.237 → 0.9487,0.5569

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| habits | wind chimes | habits | 0.0769 | 0.1777 | r |
| quests | banners | quests | 0.1538 | 0.5924 | r |
| goals | floating islands | goals | 0.8718 | 0.5569 | l |

**panda · W5 Moon Peak** (Lv 85–100, accent `#E8E2C8`) · hero (0.3436, 0.2773) · companion tap 0.2282,0.2536 → 0.7769,0.6635

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| habits | constellation | habits | 0.2872 | 0.2417 | r |
| quests | left lanterns | quests | 0.1026 | 0.4976 | r |
| goals | sky lanterns | goals | 0.8564 | 0.5355 | l |

**cat · W1 Lantern Alley** (Lv 1–24, accent `#F2B35E`) · hero (0.2359, 0.4526) · companion tap 0.3231,0.2784 → 0.8615,0.6836

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | hanging lantern | goals | 0.1026 | 0.2322 | r |
| habits | window candles | habits | 0.1795 | 0.4171 | r |
| quests | notice board | quests | 0.8769 | 0.3626 | l |

**cat · W2 Rooftop Gardens** (Lv 25–44, accent `#9CCB86`) · hero (0.2103, 0.6694) · companion tap 0.2821,0.2547 → 0.8462,0.5924

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | lantern string | goals | 0.1026 | 0.2133 | r |
| habits | herb pots | habits | 0.1538 | 0.6339 | r |
| quests | clothesline notes | quests | 0.7692 | 0.391 | l |

**cat · W3 Old Library** (Lv 45–64, accent `#C9A27A`) · hero (0.1846, 0.5569) · companion tap 0.3333,0.3199 → 0.8205,0.6635

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | hanging lamps | goals | 0.1026 | 0.2073 | r |
| habits | shelf candles | habits | 0.1282 | 0.5213 | r |
| quests | pinboard | quests | 0.7692 | 0.5095 | l |

**cat · W4 Harbor Lights** (Lv 65–84, accent `#7FB6D9`) · hero (0.159, 0.5036) · companion tap 0.4103,0.3555 → 0.8462,0.6635

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| goals | lamp posts | goals | 0.0769 | 0.3555 | r |
| habits | pier lanterns | habits | 0.1026 | 0.5391 | r |
| quests | mast pennants | quests | 0.7949 | 0.2488 | l |

**cat · W5 Starlit Rooftops** (Lv 85–100, accent `#A9B9F2`) · hero (0.7128, 0.2607) · companion tap 0.4179,0.3756 → 1.0,0.7701

| pin | object | opens | x | y | label |
|---|---|---|---|---|---|
| habits | constellation | habits | 0.7692 | 0.2251 | l |
| quests | left lanterns | quests | 0.1487 | 0.5166 | r |
| goals | sky lanterns | goals | 0.8769 | 0.4147 | l |

Fixed (all worlds): lvring (0.1026, 0.0853), chapter (0.3846, 0.0853), prayer (0.8846, 0.0853), bubble (0.5, 0.7701), streak (0.1026, 0.9147), orb (0.5, 0.9147), labels (0.8846, 0.9147)

## Forms / sprites
Pick a form with `forms[i].levels` (inclusive). `heightDp` is the suggested on-home display height on a 390-wide frame. Scale sprites by height, never stretch. Every sprite has its feet at the bottom edge, so anchor it with `Alignment.bottomCenter`. Evolving: crossfade 400 ms plus the motif burst; with reduced motion, an instant swap.

**dragon** (default name Ruu): Ember Egg 1–4 · Spark 5–9 · Kindle 10–14 · Flicker 15–19 · Hearthling 20–24 · Mossback 25–29 · Ledgewalker 30–34 · Glider 35–39 · Fernmane 40–44 · Runeling 45–49 · Bellwing 50–54 · Twin-horn 55–59 · Lanternheart 60–64 · Windrider 65–69 · Cloudcrest 70–74 · Stormhorn 75–79 · Skyheart 80–84 · Starbreath 85–89 · Aurorawing 90–94 · Crownhorn 95–99 · Lanternsky 100–100

**panda** (default name Sumi): Cub 1–24 · Bamboo Scout 25–44 · Mist Walker 45–64 · Plum Guardian 65–84 · Moon Sage 85–100

**cat** (default name Kage): Kitten 1–24 · Alley Shade 25–44 · Roof Runner 45–64 · Harbor Watcher 65–84 · Star Warden 85–100

## Orbs
256 px circles, cropped from each world's plate so the orb always matches the scene. Draw them in a 64 dp circle with a 2 dp ring in the world accent. `portraitCropRaw720x1280` records the source crop.

## Icons
UI: habits, quests, goals, prayer, money, books, movies, planner, journey, chat, settings, plus home, labels, streak, lock, undo, back, close, add, check and rupee. `rupee` is for the Budget screen only. Prayer, Movies, Books and Budget never show XP.
Motifs: dragon W1 ember, W2 leaf, W3 maple, W4 wind, W5 star. Panda: enso brush-circle in 5 world tints. Cat: slit-eye in 5 world tints.

## Palette
Base #0E0F10 · surface #16181A · raised #1F2225 · hairline #2A2E32 · text #F4EEDC · muted #B3B0A9 · dim #8F9194 · jade #3FC08A · amber #F2A93B · lavender #B9A6F2. Never red.

## Known gaps / notes
* The plates are upscaled from 720×1280 art with a light unsharp, so they look slightly soft on 3× phones. That is fine behind UI. Native high-res repaints are a later pass.
* The panda W1 plate was replaced after the v14 renders (new serious cub-in-nest art). The v14 reference screens in `docs/design/v14/screens` show the old plate, so follow this pack.
* Panda W2–W4 and Cat W2–W4 plates and hotspots are new in this pack. No v14 reference screen exists for them.
* Dragon forms 00–01, 04–06, 10, 12, 13, 15 and 20 come from darker sheets. Forms 02, 03, 07–09, 11, 14 and 16–19 come from lighter sheets with the same character design but a slightly brighter grade. If needed, unify them with a 0.92 brightness ColorFilter.
* Panda and cat inner backdrops are blurred plates, not unique painted rooms.
* The v14 reference renders are not included. They are already in the repo.
