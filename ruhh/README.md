# RUHH

Unified Flutter life tracker: **Budget** (optional), **Habit**, **Prayer**, and **Movie** modules with Neo-Brutalism UI, offline Isar storage, Supabase sync scaffold, smart notifications, and Android overlay quick actions.

## Run

```bash
cd ruhh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Configure secrets in `ruhh/.env` (see `.env.example` pattern — `.env` is gitignored).

## Reference folders

Sibling directories at the repo root (`Budget-Tracker`, `Habit-Tracker`, etc.) are **logic references only**. The shipped app lives entirely under `ruhh/`.

## Supabase

Migrations live in `supabase/migrations/`. **Do not `supabase link` a working copy to
production and do not use `--linked`.** Remote changes follow `docs/SECURITY_ROLLOUT.md`
(guard step, explicit `--project-ref` / `--db-url "$RUHH_TARGET_DB_URL"`, owner approval).
Local development:

```bash
supabase start            # disposable local stack
supabase db reset --local # applies all migrations locally
supabase test db          # pgTAP
supabase stop --no-backup
```

The app uses RPCs (`ruhh_register_user`, `ruhh_pull`, `ruhh_push`, …) with the **anon** key in `.env`. Personal access tokens are for CLI/admin only.

## App icon

Source: `assets/icon/app_icon.png`. Regenerate platform icons:

```bash
dart run flutter_launcher_icons
```

## Android quick action

1. Grant “Display over other apps” from **Settings → Quick action / Back tap setup**.
2. On Samsung One UI, set **Tap back** to launch **RUHH Quick Action** (second launcher icon).
