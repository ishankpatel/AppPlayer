# StreamVault

StreamVault is a premium local-first Flutter media app scaffold for Windows, iOS, and future TV-class targets. Windows is treated as the native local app lane; iOS is treated as a Flutter web/PWA lane that can be deployed to Cloudflare Pages.

## Current Product Surface

- Netflix-style dark UI with full-bleed hero artwork, gradient overlays, horizontal rows, animated card states, detail pages, season/episode selection, and search.
- Dynamic catalog loading through TMDB when `TMDB_API_KEY` is configured, with Cinemeta/public fallback data and local mock data for offline demos.
- Drift + SQLite local database for fast metadata and continue-watching cache.
- Supabase cloud sync scaffold for household profile, watchlist, favorites, and continue-watching state.
- media_kit player shell for Windows with subtitle/audio track selection UI and hardware-decoding status indicator where the runtime exposes it.
- Live sports screen scaffold with scoreboards and provider-handoff buttons.
- Windows desktop target checked in and ready to build from the same Flutter codebase.

## Architecture Map

- `lib/main.dart`: app bootstrap, path URL strategy for web, optional Supabase initialization, media_kit initialization.
- `lib/providers.dart`: Riverpod dependency graph for Dio, TMDB/Cinemeta remotes, Drift database, media repository, and sync repository.
- `lib/data/datasources`: remote and cloud data adapters.
- `lib/data/local`: Drift SQLite schema and local persistence.
- `lib/data/models`: app data models for media, playback progress, and user profile state.
- `lib/data/repositories`: repository layer that combines remote metadata, local cache, and cloud sync.
- `lib/presentation/home`: browse shell, hero banner, navigation, content rows, and cards.
- `lib/presentation/detail`: detail page, cast/metadata panel, and episode browser.
- `lib/presentation/search`: search UI backed by the media repository.
- `lib/presentation/player`: media_kit playback shell.
- `lib/presentation/settings`: Supabase/session and local playback settings UI.
- `lib/presentation/sports`: live sports scoreboard and stream handoff UI.
- `supabase/schema.sql`: database schema and RLS policies for the free-tier Supabase backend.
- `docs/`: system handoff notes and future feature plans.

## Windows Build Setup

Install Flutter and enable Windows desktop support:

```powershell
git clone https://github.com/ishankpatel/AppPlayer.git
cd AppPlayer

flutter config --enable-windows-desktop
flutter doctor -v
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d windows
```

If `flutter` is not on PATH on this machine, the local installation used during development was:

```powershell
& C:\dev\flutter\bin\flutter.bat doctor -v
& C:\dev\flutter\bin\flutter.bat run -d windows
```

For a release build:

```powershell
flutter build windows
.\build\windows\x64\runner\Release\streamvault.exe
```

Windows builds require Visual Studio with the "Desktop development with C++" workload. iOS and Apple TV builds require macOS with Xcode. Android TV requires the Android SDK and target-specific testing.

## Environment

The app builds and runs with no secrets. Optional service credentials are passed with `--dart-define`:

```powershell
flutter run -d windows `
  --dart-define=TMDB_API_KEY=your_tmdb_key_here `
  --dart-define=SUPABASE_URL=https://yourproject.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

`.env.example` is kept as a reference for the expected names. Without TMDB, the app uses public fallback/mock catalog data. Without Supabase, sync actions no-op locally.

## Supabase Setup

1. Create a Supabase project.
2. Enable anonymous auth if you want the current simple household session flow.
3. Run `supabase/schema.sql` in the Supabase SQL editor.
4. Pass `SUPABASE_URL` and `SUPABASE_ANON_KEY` with `--dart-define`.
5. Launch the app and use Settings -> Start Household Sync Session.

## Web / Cloudflare

See `docs/DEPLOYMENT.md` for the iOS/PWA and Cloudflare Pages path.

Quick local web test:

```powershell
flutter build web --release
powershell -ExecutionPolicy Bypass -File .\serve_web.ps1 -Port 8090
```

The repo includes Cloudflare Pages SPA fallback files in `web/_redirects` and `web/_headers`.

## Notes For The Next CLI Agent

- This is a Flutter/Riverpod app, not a web-only prototype. The web target may be used for quick visual QA, but Windows desktop is a first-class build target.
- Keep the app local-first: metadata and progress should work against SQLite first, then sync opportunistically to Supabase.
- Do not hardcode secrets. Use `--dart-define` for local service credentials and keep `.env.example` as a name reference.
- The catalog code currently prefers TMDB, then falls back to Cinemeta/public seed data, then local samples. See `MediaRepository.loadMoreCategory`.
- The player accepts a direct URL through `/player?url=...`; provider integrations should keep secrets local and avoid hardcoded keys.
- Before handing off changes, run `dart format lib test`, `flutter analyze`, `flutter test`, and at least `flutter build windows` on a Windows machine with Visual Studio C++ tooling installed.
