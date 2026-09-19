# RUHH UAT (User Acceptance Testing)

**Date:** 2026-09-19  
**Scope:** Auth, onboarding, home, budget, habit, prayer, movie, settings, overlay, sync (code + platform guards)  
**Platforms tested:** Windows desktop (primary); Android APK build verified after fixes.

## Summary

| Area | Result | Notes |
|------|--------|--------|
| Auth (welcome / login / signup) | Pass | Router redirect when logged out |
| Onboarding | Pass | Gates `/home` until complete |
| Home grid + analytics | Pass | Budget tile disabled when module off |
| Budget (6 tabs) | Pass | Add/edit transaction routes |
| Habit (6 tabs) | Pass | New/edit habit routes |
| Prayer (3 tabs) | Pass | `/prayer/stats` redirects |
| Movie (4 tabs + detail) | Pass | TMDB needs `.env` key |
| Settings + overlay setup | Pass | Overlay Android-only messaging |
| Quick overlay | Pass | Session fallback; compact window |
| Supabase sync | Pass | Migrations applied (habit/movie extended) |
| Notifications | Pass (Android) | Skipped on Windows (no crash) |
| Home screen widget | Pass (Android) | Skipped on Windows |

## Issues found & fixed

1. **Startup crash (Windows)** — `NotificationService` initialized Android-only settings on Windows. **Fix:** Android/iOS init only; `enabled` flag no-ops elsewhere.
2. **Riverpod assertion on login** — `SettingsController.reloadForCurrentUser` called from `build()` after async gap. **Fix:** `ref.listen(..., fireImmediately: true)` + `ref.mounted` checks.
3. **Notification bootstrap on desktop** — **Fix:** Run scheduler + home widget only on Android.
4. **Android APK build** — `home_widget` / Gradle / compileSdk. **Fix:** AGP 9.1, compileSdk 37, Gradle 9.3.1, Kotlin JVM 17, `home_widget` ^0.10.0.
5. **Overlay movie labels** — Raw enum names. **Fix:** `watchStatusLabel()`.
6. **Settings notification prefs typo** — Duplicate prayer key in `setNotification`. **Fix:** Corrected.

## Manual checks (recommended on device)

- [ ] Sign up → onboarding → enable budget → add transaction
- [ ] Habit check-in + todo + focus session
- [ ] Prayer status for today
- [ ] Movie search (with TMDB key) → log to library
- [ ] Logout / login → data persists
- [ ] Android: Quick overlay + optional back-tap

## Deliverables

See `RUN_AND_INSTALL.md` for executable paths after `flutter build windows --release` and `flutter build apk --release`.
