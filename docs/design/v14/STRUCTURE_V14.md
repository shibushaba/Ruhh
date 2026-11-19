# RUHH v14 · Structure: Living scene + Ruu ring (+ C's Goal climb, B's Money blocks)

Shabas picked: "Go with A plus C's goal climb and B's money blocks, build it across all worlds."
v14 builds that across all 5 worlds and adds the charcoal chrome and pet choice. It is a design preview only.

## Navigation model
1. **Home is the world.** Each world's scene objects are the menu for daily things:

| World | Habits | Quests | Goals | Extra |
|---|---|---|---|---|
| W1 Ember Nest | Candle ledge | Quest wall | Lantern | — |
| W2 Moss Ledge | Stones | Leaf post | Bridge lanterns | — |
| W3 Cliff Shrine | Bell rope | Ema rack | Stone lanterns | Big bell → Wrap-up |
| W4 Wind Temple | Chimes | Banners | Islands | — |
| W5 Star Summit | Constellation | Waiting lanterns | Sky lanterns | — |

   In every world:
   - Moon chip → Prayer.
   - Chapter title → Journey.
   - Lv ring → Settings and character.
   - Ruu's bubble → Chat.
2. **The Ruu ring reaches everything else.**
   - Hold the orb and slide to one of 6 nodes. Slide past a node to its outer arc of sub-pages, for example Money → This month / Add spend / Categories.
   - Novice path: tap the orb, then tap a node.
3. **Inner screens are non-list layouts, each with a mini orb** (tap = Home, hold = ring).

## Reach (taps from Home)
| Place | Path | Steps |
|---|---|---|
| Habits orbit | Scene pin, or ring → Habits & Quests | 1 |
| Quests board | Scene pin, or orbit switch | 1 |
| Goal climb | Lantern / island / sky-lantern pin | 1 |
| Money blocks | Ring → Money | 1 slide / 2 taps |
| Money sub-pages | Ring → Money → outer arc | 2 |
| Planner dial | Ring → H&Q → Planner, or the switch in Habits | 2 |
| Prayer sky | Moon chip, or ring → Prayer | 1 |
| Books & Movies (Night nook) | Ring → Books / Movies | 1 slide |
| Journey | Chapter title | 1 |
| Relics, Season | Journey chips | 2 |
| Chat | Ruu's bubble | 1 |
| Settings | Lv ring | 1 |
| Morning / Evening | Auto at 7:00 / 21:00; W3 big bell; Ruu's bubble | 1 |

## Gestures and their tap alternatives
| Gesture | Tap alternative | Undo |
|---|---|---|
| Hold orb + slide + release | Tap orb, then tap node | Tap outside / back closes |
| Hold a habit (0.6 s) | Tap **Light it** | **Undo** button + toast |
| Pluck a quest note | Tap **Done** | **Undo** |
| Hold milestone bead | Tap the node + confirm | **Undo** |
| Drag a planner stop | Tap **Move** | **Undo** |
| Pinch / swipe back | Mini orb tap, or system back | — |

**Reduced motion:** the ring appears without the fan, room changes become crossfades, and there are no particles.

## Accessibility fallback
- **List mode** (`dragon-w2-list-mode.png`) shows the same places as plain 56 px rows with headings. It turns on automatically with a screen reader and is a toggle in Settings → Navigation.
- Screen readers get a "Places" rotor.
- A Left-hand orb option mirrors the ring.
- **Labels chip:** shows every scene label with no overlap (W3 and W5 renders).
- **First-run demo** (`dragon-w2-first-run-demo.png`) teaches "Hold Ruu · or tap" in 3 steps, with Skip and Try it.

## Label crowding fix (W3 / W5)
v12 put a pill label on every object. v14 changes this:
- Every object is a **small pin**: icon, progress arc and count.
- **Only the focused pin** (the next habit) carries the hero pill.
- Full labels appear on first run or via the **Labels** chip.
- Labels-on renders: `dragon-w3-home-labels.png` and `dragon-w5-home-labels.png`.

## Pets
Pets share this exact map; only the art, names, accents, motif and orb portrait swap. See `PETS_V14.md`.

## Pros
- No tab bar and no card lists.
- The scene the owner liked is the real Home.
- One thumb-centre control reaches everything, and works for both hands.
- The pattern scales to pets.

## Cons and risks
- The ring is less visible than tabs. This is mitigated by the always-visible orb, its hint, the first-run demo and List mode. It still needs a 5-person "find Books" test.
- Pins are small on bright art (W4 sky).
- Hotspot positions are hand-placed per world and per pet, which is ongoing design cost for every new world.
