# Favorites and full-screen player controls

Delivered to internal TestFlight on October 23, 2026 after explicit owner approval:

- [iPhone/iPad 1.2 (13)](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/d31af2b5-6f33-408e-9af4-06ed59f069eb)
- [Mac 1.2 (31)](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/ae8cf158-6c0d-4663-afb1-01ea959d6a48)

Both builds are **VALID** and **IN_BETA_TESTING** in the existing internal
**PulseCanvas Mac Beta** group. English tester notes are published, and all 52
prior group builds were preserved (54 builds after this delivery). Application
source commit: `4d2302552cb7f1e795e920d8a1bf4a535aecea25`.

## Behavior

- Double-tap a live Studio or Radio visualizer on iPhone/iPad, including full
  screen, to save it to visualizer favorites. Mac supports double-click in its
  Visualizers, Studio, and Radio views, including presentation/full screen.
- A brief heart confirmation acknowledges the gesture. Repeating it keeps the
  favorite and its originally saved appearance. Visible heart buttons still
  toggle favorites, including removal.
- Mobile full-screen controls show the visualizer name and its heart, plus the
  song title and a separate song heart in Radio. The bar adapts to phone/tablet
  width and respects the camera and home-indicator safe areas.
- Radio's labeled **Next** button skips the song. Its station menu also works in
  full screen, with direct station choices and **Next station**, which cycles
  through the station directory and begins playback of that station.
- Swiping continues to change only the visualizer within the selected group.
  Single-tapping full screen still hides/reveals the controls; a double-tap does
  not also activate that single-tap action.
- Paused Radio progress restores from the audio model when its transport view
  reappears. Debug mobile QA runs use isolated visualizer preferences.

## Validation

- iPad Pro 13-inch (M5) simulator: five focused UI tests passed, covering both
  favorite gesture flows, both swipe regressions, and grouped landscape Radio
  controls. Favorite and transport controls fit portrait and landscape.
- iPhone 18 Pro simulator: Radio favorites/controls and both swipe regressions
  passed; the focused Studio favorite test also passed with rotation completion
  explicitly awaited. Tests cover repeated gestures, separate hearts, song and
  station changes, paused/playing state, and full-screen single-tap behavior.
- Native isolated Mac app: double-click verified in Visualizers and Studio,
  presentation, and Radio window/full screen. Repeated full-screen Radio clicks
  retain the favorite, song and paused transport position.
- Favorites backup smoke tests passed for both Creators and Store configurations,
  including appearance preservation and persistence. Radio smoke tests passed,
  including next-station playback and wraparound.
- Exported IPA and expanded Mac installer payload passed distribution-signature,
  version, profile, resource, and Release test-hook checks. Mac sandbox and
  installer signature checks passed. Apple's validation and both uploads then
  succeeded without errors. App Store Connect processing, internal tester access,
  exact tester notes, and preservation of the prior group builds were verified
  through the API. This delivery did not submit an App Store review or update
  Vision Pro/Apple TV builds.

Native screenshots, test results and review gallery:
`/Users/brad/Documents/Codex/2026-10-23/pulsecanvas-double-favorite-review/`.

Signed release candidates and package-verification receipts:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/favorite-gestures-1.2-20261023/`.
