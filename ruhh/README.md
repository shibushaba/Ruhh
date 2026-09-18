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

Migrations live in `supabase/migrations/`. Apply to your linked project:

```bash
# CLI token: create at supabase.com/dashboard (never commit sbp_ tokens)
$env:SUPABASE_ACCESS_TOKEN="sbp_..."
supabase link --project-ref gmmfimwumtbneynsyimz
supabase db push
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
