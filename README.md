# Karacookie

A floating, always-on-top, translucent overlay that shows time-synced lyrics for **Spotify and Apple Music** on macOS. **Zero setup** — install, allow once, sing along.

> Windows version in progress.

## What's in this repo

```
Sources/Karacookie/       # the macOS app — Swift, SwiftUI + AppKit
landing/                  # the marketing site — Astro
.github/workflows/        # CI/CD
```

## Develop the mac app

Needs Xcode 17 (or Swift 6.0) and macOS 14+.

```sh
make run          # build .app bundle, ad-hoc sign, launch
make build        # compile only
make clean
```

First launch: a welcome window walks you through the macOS Automation prompt. Pick a theme; lyrics flow when you press play in Spotify or Music.

## Develop the landing page

```sh
cd landing
npm install
npm run dev       # http://localhost:4321
npm run build     # → dist/
```

## Push live

### Landing page → GitHub Pages (automated)

1. Push this repo to GitHub
2. **Repo Settings → Pages → Source: GitHub Actions**
3. Edit `landing/public/CNAME` to your domain (or delete the file to use `<user>.github.io/<repo>`)
4. Push to `main` — `.github/workflows/deploy-landing.yml` builds + deploys

### macOS app → signed DMG

One-time:
```sh
xcrun notarytool store-credentials AC_PASS \
    --apple-id YOUR_APPLE_ID \
    --team-id YOUR_TEAM_ID \
    --password APP_SPECIFIC_PASSWORD
```

Each release:
```sh
export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
make sign && make notarize && make dmg
# → .build/Karacookie-1.0.0.dmg
```

Then create a GitHub Release, attach the DMG, tag it `v1.0.0`. The landing page's download buttons link to `releases/latest`.

## Features (Mac 1.0)

- **Zero Spotify/Music dev-account setup** — uses AppleScript locally
- **6 themes**: Minimal · Crystal · Bloom · Spotlight · Concert · Neon
- **Per-word karaoke wipe** with per-word pop animation (intensity adjustable)
- **Per-track color tinting** from album art
- **Per-track accent border glow** around the panel
- Adaptive polling (push-free), disk + memory caches
- Always-on-top, joins all Spaces, survives fullscreen
- Global hotkeys: `⌥⌘L` toggle visibility, `⌥⌘K` toggle click-through
- Settings: opacity, font size, word-bounce intensity, lock position, hide-when-paused, show track in menu bar, launch at login

## Architecture

```
SourceManager  ────► PlaybackEngine ────► OverlayStateBox ────► LyricsOverlayView
   │                       │                                       (SwiftUI render)
   ├── SpotifyAppleScript  ├── LyricsService (LRCLib)
   └── AppleMusicAppleScript└── AlbumArtFetcher (oEmbed / iTunes)
```

`PlaybackEngine` drift-corrects position from the source's reported `progressMs` against a local 30Hz clock, binary-searches the current line, computes per-word timings via `WordTimingInterpolator`, and publishes a single `OverlayState` to `OverlayStateBox` that the SwiftUI hierarchy observes.

Switching themes, sources, or fonts requires no engine restart — they're pure renderer/config concerns.

## License

MIT
