# RUHH v14 · Pets: Dragon, Panda, Cat (design preview)

Shabas, verbatim: "Have an option to pick the pet on the creation page and try them… Panda and… Cat… Every pet will have its own environment and everything. When selecting it the whole app will be changed and the user keeps it as it is now. We can't change it."

All three are **original characters** in a serious-cool 2D anime style. None is chibi or childish.
- The Panda wears a jade sash and an amber bead, has no martial-arts outfit, and is deliberately unlike Kung Fu Panda's Po.
- The Cat is a sleek dark-grey cat with amber eyes and a jade scarf, and resembles no existing cartoon cat.

Every pet uses the same 5-stage, 100-level climb, the same sample data and the same rules: XP exclusions, INR only in Money, and never red.

## Lore (one line each)
- **Dragon: Ruu.** Hatches in an ember nest and climbs to the stars; patience made visible.
- **Panda: Sumi** (default name, meaning "ink"; the user renames it). A quiet guardian of bamboo and mountain. It keeps your rhythm the way a brush keeps a line: one steady stroke a day.
- **Cat: Kage** (default name, meaning "shadow"). A night walker of alleys and rooftops. It notices everything, says little, and climbs toward the stars one roof at a time.

## Worlds and forms
| Stage | Levels | Dragon world · form | Panda world · form | Cat world · form |
|---|---|---|---|---|
| 1 | 1–24 | Ember Nest · Ember Egg → Hearthling | Bamboo Hollow · Cub | Lantern Alley · Kitten |
| 2 | 25–44 | Moss Ledge · Mossback / Ledgewalker | Mist Terraces · Bamboo Scout | Rooftop Gardens · Alley Shade |
| 3 | 45–64 | Cliff Shrine · Bellwing / Lanternheart | River Gorge · Mist Walker | Old Library · Roof Runner |
| 4 | 65–84 | Wind Temple · Windrider / Stormhorn | Plum Cloud · Plum Guardian | Harbor Lights · Harbor Watcher |
| 5 | 85–100 | Star Summit · Starbreath → Lanternsky | Moon Peak · Moon Sage | Starlit Rooftops · Star Warden |

## Accents and motif
These are the per-pet ACC / ACC2 values. Chrome stays charcoal for every pet.

| | W1 | W2 | W3 | W4 | W5 | Ring / nav motif |
|---|---|---|---|---|---|---|
| Dragon | #F2A23A | #7BD389 | #E2A65C | #6CC3E8 | #F0C75E | Per-world: ember, leaf, maple, wind, star |
| Panda | #D9C08A | #A8D5A2 | #8FC9C2 | #E3A9C4 | #E8E2C8 | Ensō brush circle |
| Cat | #F2B35E | #9CCB86 | #C9A27A | #7FB6D9 | #A9B9F2 | Slit-eye diamond |

Scene hotspots per pet:
- **Panda W1:** lantern → Goals, stone lamps → Habits, bamboo post → Quests.
- **Panda W5:** constellation → Habits, lanterns → Quests, sky lanterns → Goals.
- **Cat W1:** lantern → Goals, window candles → Habits, notice board → Quests.
- **Cat W5:** constellation → Habits, lanterns → Quests, sky lanterns → Goals.

## Onboarding flow
1. **Picker** (`pet-1-picker.png`): a card carousel with the selected card large and the others peeking. Swipe, or tap a side card. Buttons: **Try** and **Choose**.
2. **Try** (`pet-2-try-panda.png`, `pet-2-try-cat.png`):
   - Temporarily themes a sample Home: W1 art, accents, motif, orb portrait and Ruu-voice lines.
   - Shows the banner "Trying Panda · nothing is saved" and a 45 s soft timer.
   - Buttons: **Back to pets** / **Choose Panda**. Nothing is written.
3. **Permanent confirm** (`pet-3-confirm-panda.png`):
   - Says plainly: "This is the one choice in RUHH you can't change later."
   - Lists what changes and notes that renaming is allowed but swapping is not.
   - Requires the check "I understand this is permanent" before **Choose Panda for good**.
4. Then naming and the call name, as before.

## How the theme swaps
- One `petId` drives a theme bundle: art set (5 world scenes and inner backdrops), world names, form names, ACC/ACC2 tables, motif painter, orb portrait crop, and line pack. Ruu's lines are re-voiced per pet; the user's call name ("Shabas") stays.
- **Navigation, components, data, XP rules and copy structure are identical.** Only the bundle swaps, so all three pets share one code path.
- In the renders this is the `set_pet()` call in `tools/core14.py`.

## The "can't change" rule: data decision needed
- For now, the design assumes `petId` is **stored locally in the user profile on device**, written once at the confirm step and read-only afterwards.
- There are **no database, auth or Supabase changes** in this work.
- Open questions to decide later:
  - Sync and backup behaviour: should a restore keep the pet?
  - Whether "reset everything" may re-open the picker.
  - Whether support can ever change it.
  - Analytics on try-versus-choose.

## Renders
- Panda: `panda-w1-home.png`, `panda-w5-home.png`, `panda-w5-ring.png`, `panda-w1-habits-orbit.png`, `pet-panda-forms.png`
- Cat: `cat-w1-home.png`, `cat-w5-home.png`, `cat-w5-ring.png` (Money sub-ring), `cat-w5-goal-climb.png`, `pet-cat-forms.png`
- Generated art is in `raw/`: panda-w1, panda-w5, cat-w1, cat-w5, panda-forms, cat-forms. W2–W4 scenes for Panda and Cat are **not drawn yet**.
