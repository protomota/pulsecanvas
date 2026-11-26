# iPhone and iPad native app — October 19, 2026

The previously untracked `mobile/` folder contained two model/document files,
with no app target or interface. Those files have been reviewed and extended
into an initial universal SwiftUI app. All source stays on `main`.

## Implemented

- `PulseCanvasMobile.xcodeproj`, deterministic generator, build/resource scripts,
  independent build number 1 and shared marketing version 1.1.5. Device families
  1 and 2 support iPhone and iPad; minimum OS is 18. No specific “Duo” simulator
  or hardware behavior is claimed. Layout responds to available window width.
- The tablet layout has a library beside the preview; smaller widths use a
  library sheet. Slider controls use an adaptive grid in a separate sheet.
  Studio/Radio stays at the upper left; the extra PulseCanvas header text was
  removed at the owner's request.
- Shared production Metal renderer, PCM analysis, beat-driven motion, Studio
  bars, common settings, timeline randomization, scene selection/playback,
  loop, favorite looks and autosave. File import/export uses `.pulsecanvas`
  projects with soundtrack relocation. Importing audio returns to Studio.
- Server-driven Radio stations, song favorites/favorites station, visualizer
  group filters and randomization. Removed-song cleanup runs at launch using
  the shared complete-catalog reconciliation logic.
- Full-screen viewing with playback, randomization, project-aspect fit and
  four-second control hiding during playback. Tap reveals the controls.
- Real MP4 rendering with audio, progress, ETA, cancellation and a Files save
  picker. Format controls offer 720p/1080p/4K and 24/30/60fps. About & Support
  retains rating/share/feedback, storefront-gated tips, source and legal links.
  A completed Files save advances the shared second-video StoreKit milestone.
- Native-only allowlisted resources and the existing app icon at an opaque
  1024×1024. The shared renderer avoids publishing a redundant nil error while
  SwiftUI creates the Metal view. Mac's experimental 120fps option is unchanged;
  iOS uses the same frame-rate limits as Vision Pro.

## Verification

- Release device build: `BUILD SUCCEEDED`, exit 0. Final bundle inspection
  confirms version/build 1.1.5 (1), both device families, all 336 active native
  effects, matching shader/catalog/soundtrack/license/privacy bytes, no external
  preset/engine/updater assets or linkage, and no Debug QA launch string.
- iPad portrait UI suite passed: one test, zero failures, 42.113 seconds.
- Initial iPhone 17 UI suite passed: one test, zero failures, 48.053 seconds.
- Final iPhone 17 suite including a real MP4 render passed: one test, zero
  failures, 38.846 seconds. iPad landscape equivalent passed: one test, zero
  failures, 38.216 seconds. These cover playback, style sliders, selection of
  Mercury Fold, full-screen entry/exit and the real export flow through the
  completed-movie/Save video state.
- The actual iPhone and iPad movies were copied from their simulator sandboxes
  and fully decoded. Both are 1280×720 H.264, 30fps, 240 frames, approximately
  eight seconds, with AAC audio. Decoded moving visual frames were inspected.
- UI tests use a Debug-only eight-second demo excerpt and isolated project
  directory. Release excludes this hook. Build products, movies and screenshots
  remain outside Git on the Music drive.
- Test runners stalled after their completed suites and were terminated during
  cleanup; normal exit-0 test-command completion is not claimed. A first iPhone
  18 Pro simulator runner failed to launch (system-shell error), so the actual
  phone checks used iPhone 17. An early landscape test targeted the obscured
  sidebar search instead of the modal; unique identifiers fixed the test. An
  early diagnostic run rendered the full demo because Debug was not defined;
  it was canceled, the configuration fixed, and the short tests passed.
- Final device compilation covers subsequent larger search styling, empty
  favorite-song guidance, opening projects from Files, correct Radio presentation
  routing and reuse of the completed render ID for save milestones. Those last small
  changes did not trigger another full UI-suite run.

Not verified: physical-device installation/performance, sustained 4K/60 export,
all effects rendered individually on iOS, document-provider save completion,
project exchange on physical devices, background Radio playback or StoreKit
sheet display. This is a local implementation, not an App Store/TestFlight
release. No existing Mac or Vision App Review submission was changed.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Mobile QA/` contains logs,
screenshots, actual sample exports, decoder checks and `artifact-receipt.json`.
The unsigned device app is at
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-device/Build/Products/Release-iphoneos/PulseCanvas Mobile.app`.
Open `PulseCanvasMobile.xcodeproj` to build/run a simulator; an unsigned simulator
or device product is not a TestFlight installer.
