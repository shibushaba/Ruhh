# RUHH v14 · Design system tokens (design preview)

## What changed from v12/v13
Only the **UI chrome** changed. The jade-tinted night chrome is now neutral charcoal, as Shabas asked ("dark-themed, black or grey… keep the dragon and the environment as it is… don't make it too fancy").

- **Art is untouched.** The dragon, every environment and all illustrations are unchanged.
- **Decoration stays at Level B.** One motif per component, a 1 px accent outline at about 40%, and glow only on progress and the single hero action. No gems, bells, crests or carved frames.
- **Fonts stay pairing 2.**
  - Mochiy Pop One for titles.
  - Zen Maru Gothic for body and labels.
  - Kiwi Maru for Ruu's lines.
  - Noto Sans Malayalam and Noto Naskh Arabic as script fallbacks.
  - **Noto Sans Malayalam is also the ₹ fallback.** None of the pairing-2 fonts has U+20B9. In Flutter, add it to `fontFamilyFallback`.

## Neutral chrome
| Token | v12 (jade night) | **v14 (charcoal)** | Use |
|---|---|---|---|
| base | #0B1A17 | **#0E0F10** | Screen ground, scrims, pins |
| surface | #112622 | **#16181A** | Panels, tiles (also every world's panel tint) |
| raised | #17332D | **#1F2225** | Selected cards, secondary button |
| hairline | #24463E | **#2A2E32** | Dividers, ring track on W5, inactive tracks |
| line-strong | #3B6E5E | **#3A3F44** | Connectors, post, empty arcs |
| text | #F4EEDC | #F4EEDC (warm off-white) | Primary text |
| muted | #B5C4BB | **#B3B0A9** | Secondary text |
| dim | #9FB5AC | **#8F9194** | Tertiary, rested/off states |

## Accents only
These hues are not used as surfaces:
- **Jade #3FC08A:** the primary button, XP and the Lv ring.
- **Amber #F2A93B:** streaks.
- **Lavender #B9A6F2:** Prayer only. It is never scored and earns no XP.
- **Never red.** Missed or rested states use dim grey.

## Per-world accent (ACC / ACC2) and motif, Dragon
| World | ACC | ACC2 | Motif | Ring track |
|---|---|---|---|---|
| W1 Ember Nest | #F2A23A | #FFD08A | Ember drop | Solid line |
| W2 Moss Ledge | #7BD389 | #C9F2A0 | Leaf | Dotted |
| W3 Cliff Shrine | #E2A65C | #F2D3A2 | Maple | Double hairline |
| W4 Wind Temple | #6CC3E8 | #C3E9F7 | Wind curl | Long dashes |
| W5 Star Summit | #F0C75E | #F6E3A6 | 4-point star | Star beads |

The Panda and Cat tables are in `PETS_V14.md`. Panels use the neutral surface in every world, so the world only shows through the accent, the motif, the ring track and the companion portrait (see `screens/80-ring-evolution-sheet.png`).

## Navigation components (new in v14)
- **Ruu orb.** 64 px, bottom centre, with the companion portrait and a world-accent outline. Five dots show "there's a ring here". Hold opens the ring; tap also opens it.
- **Ring.** A half-ring of 6 nodes (Home, Prayer, Money, Habits & Quests, Books, Movies).
  - Radius 160, nodes 52–60 px, labels above the nodes.
  - Sliding past a node opens an outer arc of 3 sub-pages.
  - A peek card at the top shows the selected node's live numbers.
- **Mini orb.** 48 px, bottom centre on every inner screen. Tap goes Home; hold opens the ring.
- **Scene pin.** A 34 px visual on a 44 px target, with an icon, a progress arc and a count badge.
  - The label shows only on focus, on first run, or when the **Labels** chip is on. This is the fix for label crowding in W3 and W5.
- **Hero pill.** Exactly one per screen (for example "Hold · Write").
- **Speech bubble.** Ruu speaks from the orb: the bubble sits in the thumb band with its tail pointing at the orb. Tapping it opens Chat.
- **Chips.** Streak (amber, bottom-left), Labels (bottom-right), Prayer moon (top-right).

## Rules kept
- 44 px minimum targets.
- Every gesture has a tap alternative (hold → tap + button; pluck → Done; slide → tap node).
- Undo on every log.
- Reduced motion: the ring has no fan animation, there are no particles, and glows are static.
- INR appears only in Money. Prayer, Movies, Books and Budget never earn XP.
- Story voice; the call name is "Shabas".
- The light theme is **dropped** in v14 (the owner asked for dark). It can return later as a secondary option built from the same tokens.
