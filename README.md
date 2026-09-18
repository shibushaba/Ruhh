# RUHH

**One life. One tracker.**

Unified Flutter app for **Budget**, **Habit**, **Prayer**, and **Movie** tracking — neo-brutal UI, offline-first (Isar), optional Supabase sync, notifications, and Android overlay quick actions.

## Download (Android)

One-click APK from GitHub Releases:

https://github.com/shibushaba/Ruhh/releases/latest/download/ruhh.apk

Portfolio landing: https://shabas.vercel.app/ruhh

## Run from source

```bash
cd ruhh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Configure secrets in `ruhh/.env` (see `.env.example` if present — `.env` is gitignored).

## Layout

| Path | Purpose |
| --- | --- |
| `ruhh/` | Shipped Flutter app |
| `UI/` | Neo-brutalism UI package (path dependency) |
| `Budget-Tracker/`, `Habit-Tracker/`, … | Logic references only |

## App icon

Source: `ruhh/assets/icon/app_icon.png`

```bash
cd ruhh
dart run flutter_launcher_icons
```
