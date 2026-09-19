# RUHH — run & install (v1.0.2+3)

## Final build artifacts (UAT pass)

| Platform | File |
|----------|------|
| **Windows (release)** | `c:\Users\shabasvp\OneDrive\Documents\Ruhh\ruhh\build\windows\x64\runner\Release\ruhh.exe` |
| **Android (release APK)** | `c:\Users\shabasvp\OneDrive\Documents\Ruhh\ruhh\build\app\outputs\flutter-apk\app-release.apk` |

UAT notes: see `UAT.md` in this folder.

PowerShell:

```powershell
Set-Item -Path "env:ProgramFiles(x86)" -Value "C:\Program Files (x86)" -ErrorAction SilentlyContinue
cd "c:\Users\shabasvp\OneDrive\Documents\Ruhh\ruhh"
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows
```

If Windows build fails with missing `windows\flutter\ephemeral\...`, run `flutter clean` then `flutter pub get` again (OneDrive sync can interrupt ephemeral files).

## Built app files (after successful build)

| Platform | Path |
|----------|------|
| **Windows (debug)** | `ruhh\build\windows\x64\runner\Debug\ruhh.exe` |
| **Windows (release)** | `ruhh\build\windows\x64\runner\Release\ruhh.exe` |
| **Android (debug APK)** | `ruhh\build\app\outputs\flutter-apk\app-debug.apk` |
| **Android (release APK)** | `ruhh\build\app\outputs\flutter-apk\app-release.apk` |

Build commands:

```powershell
flutter build windows --debug
flutter build apk --debug
flutter build apk --release
```

## Secrets

Copy `ruhh\.env.example` → `ruhh\.env` and set:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `TMDB_API_KEY` (movies)

## Supabase (already linked)

Project ref: `gmmfimwumtbneynsyimz` — migrations in `supabase/migrations/`.

## Android overlay

Settings → Quick action → grant **Display over other apps**, then use home **Quick** FAB or Samsung back-tap.
