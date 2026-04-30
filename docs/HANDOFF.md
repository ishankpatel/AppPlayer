# StreamVault Handoff Notes

These notes are written for a follow-on CLI/code agent that needs to understand, build, and extend the project on Windows.

## Intent

StreamVault is a local-first, premium media browsing and playback shell built with Flutter. Windows desktop and iOS are the current primary targets. TV targets should be kept in mind through focusable controls, remote-friendly navigation, and separation between UI, repositories, and platform-specific playback concerns.

External playback-provider connectors are intentionally not part of this repository handoff. The app keeps the native player screen and direct URL route so an authorized provider module can be added later without changing the browse/detail/player architecture.

## Runtime Flow

1. `lib/main.dart` initializes Flutter bindings, media_kit, and Supabase when compile-time environment values are configured.
2. `ProviderScope` overrides `supabaseConfiguredProvider` so settings and sync know whether cloud calls should run.
3. `StreamVaultApp` builds the GoRouter routes:
   - `/`: home browse shell.
   - `/search`: search page.
   - `/detail`: title detail page, usually receiving a `MediaItem` in `state.extra`.
   - `/player`: media_kit player shell; accepts an optional direct `url` query parameter.
   - `/settings`: Supabase status, local playback capabilities, and cache notes.
4. `MediaRepository` loads rows dynamically:
   - TMDB when `TMDB_API_KEY` is configured.
   - Cinemeta/public fallback catalogs when TMDB is not configured.
   - Built-in sample data as the final offline fallback.
5. Drift persists media cache and playback progress locally.
6. Supabase sync is non-blocking. If Supabase is not configured, sync calls return without breaking local behavior.

## Important Files

- `lib/providers.dart`: dependency graph.
- `lib/data/repositories/media_repository.dart`: catalog loading, search, pagination, local fallback.
- `lib/data/local/local_database.dart`: Drift schema and local persistence helpers.
- `lib/data/datasources/tmdb_remote.dart`: TMDB metadata calls.
- `lib/data/datasources/cinemeta_remote.dart`: public metadata fallback calls.
- `lib/data/datasources/supabase_sync.dart`: cloud sync adapter.
- `lib/presentation/home/home_screen.dart`: browse shell, navigation, row loading.
- `lib/presentation/home/widgets/media_row.dart`: horizontal row and incremental loading behavior.
- `lib/presentation/detail/detail_screen.dart`: large detail view, episode browser, playback handoff panel.
- `lib/presentation/player/player_screen.dart`: media_kit player, track sheets, progress sync hooks.
- `supabase/schema.sql`: profiles, watchlist, continue_watching, favorites, indexes, RLS, profile trigger.

## Windows Build Checklist

Required machine setup:

- Flutter stable with Windows desktop enabled.
- Visual Studio with "Desktop development with C++".
- Git.

Commands:

```powershell
git clone https://github.com/ishankpatel/AppPlayer.git
cd AppPlayer

flutter config --enable-windows-desktop
flutter doctor -v
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
flutter build windows
.\build\windows\x64\runner\Release\streamvault.exe
```

If this development machine's local Flutter install is still being used:

```powershell
& C:\dev\flutter\bin\flutter.bat pub get
& C:\dev\flutter\bin\flutter.bat build windows
```

## Environment Variables

The app uses optional compile-time values. A fresh clone builds without them.

```powershell
flutter run -d windows `
  --dart-define=TMDB_API_KEY=your_tmdb_key_here `
  --dart-define=SUPABASE_URL=https://yourproject.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

`.env.example` is only a reference for expected names. Do not make remote services required for the local browse experience.

## Supabase Notes

The current auth approach is intentionally simple: anonymous household session support through Supabase auth. A future pass can replace this with shared passphrase, magic link, or family profile switching. Any change should preserve these rules:

- Local cache works without cloud.
- Sync failure must not block browsing or playback.
- Watchlist, favorites, progress, and preferences should remain mergeable per household/profile.
- Never commit real project keys.

## Product Gaps For Next Agent

- Wire real watchlist/favorites buttons into Drift and Supabase rather than placeholder CTAs.
- Improve TV/focus navigation: visible focus rings, remote-control shortcuts, and row snapping.
- Add richer TMDB detail loading for episode-specific stills, cast, trailers, and season metadata.
- Replace remaining fallback art with better runtime metadata where possible.
- Add provider modules only through authorized, documented APIs or deep links.
- Add integration tests for row pagination, search, detail navigation, and player progress persistence.

## Guardrails

- Keep Flutter/Riverpod patterns consistent with the current files.
- Prefer repository-level changes over UI networking calls.
- Keep secrets, build output, screenshots, and local caches out of git.
- Avoid hardcoded secrets and machine-specific absolute paths in source code.
- Run analyze/test/build before pushing changes.
