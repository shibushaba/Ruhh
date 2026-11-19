# How RUHH is released today

Checked on 18 November 2026. Nothing in this note was triggered.

## What exists

- The Android app is built by hand. `ruhh/RUN_AND_INSTALL.md` and the root `README.md` say to run `flutter build apk --release` and install `ruhh/build/app/outputs/flutter-apk/app-release.apk`.
- On Flutter 3.44 that release command stops in icon tree-shaking because `ruhh/lib/core/icons/app_icons.dart` builds Phosphor `IconData` from code points. The build that succeeds is `flutter build apk --release --no-tree-shake-icons`. The release build type still signs with the debug key.
- The published download is a GitHub Release asset, linked from the root README: `https://github.com/shibushaba/Ruhh/releases/latest/download/ruhh.apk`.
- A portfolio page links the same app: `https://shabas.vercel.app/ruhh`. That page is not built from this repository.
- `ruhh/android/app/build.gradle.kts` signs release with the debug key. There is no Play Store, Fastlane, or Firebase config in this repo.
- This repository has no GitHub Actions workflow for the Flutter app. The only workflows are under `UI/.github/` and they publish the neo-brutalism package, not RUHH.
- There is no `ruhh/web` target. `ruhh/lib/main.dart` imports `dart:io`, so the current app does not compile for web without a separate change.
- Supabase changes are applied by hand with `supabase db push` against project `gmmfimwumtbneynsyimz`. This build does not include a migration and must not be pushed there.

## What merging this branch to `main` would do

Nothing automatic. There is no workflow on `main` that builds an APK, uploads a release, deploys the web, or runs `supabase db push`.

The merge itself would still land every commit on this branch that is not already on `main`. That includes the Phase 0 audit, the Phase 1 design, the visual studies, the approved v14 design, and this Flutter build. Those earlier commits are ancestors of `cursor/v14-build-50e3`, so they come along even though their pull requests are still open.

Merging is held until Shabas confirms.
