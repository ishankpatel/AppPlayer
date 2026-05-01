# StreamVault Deployment

StreamVault has two lanes:

- Windows: native Flutter desktop build.
- iOS: Flutter web/PWA deployed as a static site.

## Local Windows App

```powershell
flutter pub get
flutter analyze
flutter test
flutter build windows
.\build\windows\x64\runner\Release\streamvault.exe
```

## Local iOS/PWA Web Test

Build:

```powershell
flutter build web --release
```

Serve with SPA fallback:

```powershell
powershell -ExecutionPolicy Bypass -File .\serve_web.ps1 -Port 8090
```

Open the LAN URL from the same Wi-Fi network on iPhone, then use Safari:

```text
Share -> Add to Home Screen
```

The local server supports direct paths such as `/search`, `/sports`, and `/my-list`, matching Cloudflare Pages behavior.

## Cloudflare Pages

The repo includes:

- `wrangler.toml`: Cloudflare Pages output directory.
- `web/_redirects`: SPA fallback for clean Flutter web paths.
- `web/_headers`: production response headers and cache behavior.
- `.github/workflows/cloudflare-pages.yml`: GitHub Actions deployment.

Required GitHub repository secrets:

```text
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
TMDB_API_KEY
SUPABASE_URL
SUPABASE_ANON_KEY
```

Recommended Cloudflare setup:

1. Create a Cloudflare Pages project named `streamvault`.
2. Create a Cloudflare API token with Pages edit/deploy permissions.
3. Add the secrets above in GitHub repo settings.
4. Push to `main` or run the workflow manually.

Manual deploy after login:

```powershell
flutter build web --release `
  --dart-define=TMDB_API_KEY=$env:TMDB_API_KEY `
  --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY

wrangler pages deploy build/web --project-name=streamvault
```

## Supabase

The schema lives in `supabase/schema.sql`.

Setup:

1. Create a Supabase project.
2. Enable anonymous sign-ins in Authentication settings if using the current household session flow.
3. Run `supabase/schema.sql` in the SQL editor.
4. Copy the project URL and anon key.
5. Provide them to the app at build time with:

```powershell
--dart-define=SUPABASE_URL=https://your-project.supabase.co
--dart-define=SUPABASE_ANON_KEY=your-anon-key
```

The app is still local-first. If Supabase is missing or offline, browsing and local state should continue to work.
