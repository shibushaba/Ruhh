# Motion for the Phase 1 frames

These timings are for a later build. The PNGs are the settled frames. Nothing in the app animates yet.

The desk does not bounce, spin, or shake. A miss never gets a motion. Motion only confirms something that was recorded.

## Level moment

The sheet in `levelup-*.png` is the middle of this sequence. Behind it, the seal still shows the old level until Continue.

| Time | What moves | Reduced motion |
| --- | --- | --- |
| 0 ms | Scrim fades to its final opacity. Sheet is in place. | Scrim and sheet appear together. |
| 80–420 ms | Four squares travel 14 px outward and fade. Colours are the existing mint, amber, sky, and lavender. | No squares. |
| 120–300 ms | The level numeral settles. It does not scale past 1. | Numeral is final immediately. |
| On Continue, 280 ms | The seal and the bar on Home take their new values. The bar grows from the old width to the new width. | Seal and bar jump. |

Total with motion is under half a second before the person can read the reason. The reason text is never delayed.

## Smaller feedback

| Event | Motion | Reduced motion |
| --- | --- | --- |
| Habit, task, or quest checked | The square fills in 160 ms. The row does not move. | Fill is instant. |
| Milestone marked done | That step's square fills mint in 200 ms. The "you are here" label moves to the next step after the fill. | Both are instant. |
| XP line on a completed row | "+8" fades in over 200 ms next to the row. It is the amount the service returned. | Text is present immediately. |
| Undo | No reverse animation. The check clears and the copy says the ledger row was reversed. | Same. |
| New goal created | The new goal card is in the list. No confetti. | Same. |

## What does not move

- Prayer marks.
- Domain reorder, except the row following the finger while it is dragged. On release it sits. Reduced motion still allows the drag, because that is the control, and skips any settle animation.
- Seasons ending. The lifetime number does not tick backward, because it does not change.

## Accessibility

- Reduced motion follows the system setting when this is built.
- The level sheet's Continue button is available at 0 ms. Motion is not a gate.
- Colour is paired with the stamp word (Habit, Quest, Project, Goal, Prayer) so a fill is not the only signal.
