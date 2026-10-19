# PulseCanvas Studio for iPhone and iPad

A native SwiftUI interface for the same Metal, soundtrack analysis, Studio,
Radio, favorite-settings and video-export models used by the Mac app.

- Wide tablet windows show a visualizer library beside the preview. Compact
  windows and phones use sheets for the library and slider controls.
- Studio includes per-scene bar lengths, scene playback, common settings,
  timeline randomization, autosave and Mac-compatible `.pulsecanvas` files.
- Radio uses the server's station directory, category/favorites music queues,
  saved song hearts and the shared visualizer filters. Saved songs are reconciled
  at launch after a successful full-catalog fetch.
- Radio has Play/Pause, elapsed/duration and a seekable song timeline. An empty
  visualizer-favorites selection falls back to random visuals with a status
  message; saved category/collection limits still apply. Retry is shown only
  after a catalog-loading failure.
- Full-screen viewing includes playback, randomization and aspect fit. Controls
  hide after four seconds while playing; tap to reveal them.
- Export offers 720p, 1080p and 4K, at 24/30/60 fps with audio, progress, ETA,
  cancellation and a Files destination picker. There is no embedded movie player.
- The native effect catalog and original app icon are reused. The target is
  `STORE_BUILD`; external engines, preset packs and updater frameworks are absent.
- About & Support retains Protomota, LLC credits, licensing, source and support
  links. StoreKit controls automatic review prompt presentation; only a completed
  Files save advances the second-video review milestone.

## Build

Open `PulseCanvasMobile.xcodeproj` and choose `PulseCanvasMobile`, or run:

```sh
PULSECANVAS_DERIVED_DATA='/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-release' bash scripts/build-mobile.sh
```

The project generator is `scripts/generate-mobile-project.py`. The minimum OS
is iOS/iPadOS 18; device families are iPhone and iPad. `Version.xcconfig` shares
the marketing version, while `mobile/Release.xcconfig` has its own build number.

The UI test uses `-PCMobileQA`, an eight-second demo excerpt and an isolated
project directory. This hook is compiled only in Debug. It tests real playback,
style sliders, selection, presentation and actual MP4 rendering. Set
`TEST_RUNNER_PC_MOBILE_LANDSCAPE=1` for the landscape layout.

This is an initial mobile implementation. Simulator results do not establish
physical-device performance, Files-provider behavior or sustained 4K export.
Signing, TestFlight distribution and App Store listing preparation are separate
from local builds. The Mac and Vision review submissions are not changed.
