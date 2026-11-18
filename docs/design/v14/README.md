# RUHH v14 (approved design)

Structure **A + C's Goal climb + B's Money blocks** across all 5 worlds, with charcoal chrome and pet choice. Approved by Shabas. This folder is the design record. Stage E is an implementation plan only (`STAGE_E_FLUTTER_PLAN.md`). No Dart, database, auth, Supabase, or production changes are in this commit.

## Docs
- `STRUCTURE_V14.md`: navigation model, reach table, gestures and tap alternatives, accessibility, crowding fix.
- `DESIGN_SYSTEM_V14.md`: charcoal tokens, accents, components.
- `PETS_V14.md`: pets, worlds, forms, swap, the permanent-choice data note.

## screens/

### Dragon homes
- `dragon-w1-home` … `dragon-w5-home`
- `dragon-w3-home-labels` and `dragon-w5-home-labels` (Labels chip on)

### Ring
- `dragon-w1-ring`, `dragon-w3-ring`, `dragon-w5-ring` (ring evolving by world)
- `dragon-w2-ring-sub-money` (sub-ring)

### Inner screens (W2)
- `dragon-w2-habits-orbit`
- `dragon-w2-quests-board`
- `dragon-w2-goal-climb`
- `dragon-w2-money-blocks`
- `dragon-w2-planner-dial`
- `dragon-w2-journey`
- `dragon-w2-prayer-sky`
- `dragon-w2-books-movies`
- `dragon-w2-chat`
- `dragon-w2-settings`
- `dragon-w2-level-up`
- `dragon-w2-morning`
- `dragon-w2-evening`

### Inner screens in other worlds
- `dragon-w5-habits-orbit`
- `dragon-w3-goal-climb`

### Onboarding and accessibility
- `dragon-w2-first-run-demo`
- `dragon-w2-list-mode`

### Pets
- `pet-1-picker`
- `pet-2-try-panda`, `pet-2-try-cat`
- `pet-3-confirm-panda`
- `panda-w1-home`, `panda-w5-home`, `panda-w5-ring`, `panda-w1-habits-orbit`
- `cat-w1-home`, `cat-w5-home`, `cat-w5-ring`, `cat-w5-goal-climb`
- `pet-panda-forms`, `pet-cat-forms`

### Sheets
- `80-ring-evolution-sheet`
- `92-sitemap-flow`
- `90-contact-dragon`
- `91-contact-pets`

## tools/
- `core14.py`: palette remap, pets, components
- `homes14.py`, `ring14.py`, `inner14.py`, `sheets14.py`, `pets14.py`, `contact14.py`

To render, run each module with `python3`. All text and numbers are drawn in code.
