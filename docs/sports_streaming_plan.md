# Sports Streaming Plan

## IPL Rights Snapshot

- United States and Canada: Willow by Cricbuzz is the official cricket streaming route for IPL and other major cricket rights. It supports web, mobile, Apple TV, Android TV, Roku, Fire TV, Chromecast, Google TV, and TV-provider sign-in.
- India: JioStar positions TATA IPL across Star Sports Network and JioHotstar.
- Free legal options are region-limited. Current guides point to Cricbuzz live streaming in select MENA countries, and free trials from licensed services in some markets. The app should not scrape or embed unlicensed iframe streams.

## Recommended Product Route

1. Add a Sports section with provider cards for IPL.
2. Use official metadata endpoints where available for schedules, standings, scores, highlights, and match details.
3. For live playback, use a provider handoff first: deep link to Willow/Cricbuzz/JioHotstar/Kayo/Sling depending on region and user preference.
4. Add native live playback only where a provider offers an authorized embed, SDK, TV Everywhere handoff, M3U entitlement, or partner API.
5. Store sports provider credentials/tokens per-device in secure storage, never in Supabase.

## Implementation Notes

- Do not use random free iframe sites. They are unstable, usually violate broadcast rights, and would break TV/app-store review.
- The first safe implementation can be schedule + score + authorized watch buttons.
- A future provider adapter can expose: `listLiveEvents`, `eventDetails`, `watchOptions`, `openProvider`, and optionally `playEntitledStream`.
