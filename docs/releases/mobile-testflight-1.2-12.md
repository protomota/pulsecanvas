# iPhone and iPad TestFlight — 1.2 (12)

Owner-approved combined update, uploaded October 23, 2026.
Application source: `a5aef74`.

## Changes

- Swipe left or right on Studio or Radio visualizers, in editor previews and
  full screen, to choose another look from the selected group. Swipes preserve
  the song, playback position and playback/pause state; Studio retains its
  current scene. Vertical drags, tiny movements and full-screen tap controls
  retain their existing behavior. VoiceOver has a Change visualizer action.
- Large-iPad onboarding centers the artwork and text between the header and
  navigation. Larger headings, descriptions and lesson text remain consistently
  left-aligned through all five slides in portrait and landscape.
- Radio groups Favorite songs, the station picker and Next song at the trailing
  edge with eight-point gaps.

## Verification

- The four focused swipe checks passed on iPhone 18 Pro and iPad Pro 13-inch
  (M5) simulators, covering editor/full-screen views, both swipe directions,
  selected-group membership, unchanged paused music position and current
  song/Studio scene, retained playback, vertical/tiny drags and full-screen taps.
- Previously approved layout checks passed for large-iPad centering, larger text,
  fixed title/description positions across all slides and both orientations,
  onboarding swipes, large text and exact Radio action gaps. iPhone onboarding
  and Radio-control regressions also passed. Native screenshots were reviewed.
- A fresh signed Release archive and App Store distribution export were created
  from the combined approved source. The earlier layout-only build-12 candidate
  was retained and never uploaded.
- The exported IPA passed strict signature and distribution-profile checks,
  source-matched resource verification, transparent onboarding artwork checks
  and Debug-hook exclusion. It contains the new preview-swipe accessibility hint,
  supports iPhone and iPad, and includes all 336 native effects.
- Apple package validation and upload succeeded without errors.

These checks used simulators and signed artifact inspection; physical-device
touch/performance checks are not claimed.

## Delivery

Apple processing completed with **VALID**. Fresh App Store Connect API readback
confirms iOS **1.2 (12)** is **IN_BETA_TESTING** in the existing **PulseCanvas Mac
Beta** internal group. All 51 previous builds were retained; the group now holds
52 builds. English tester notes were saved and read back exactly.

- [TestFlight build 1.2 (12)](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/70b4f799-71d6-4737-8d90-e1db208a3fc0)
- [Application source](https://github.com/protomota/pulsecanvas/commit/a5aef74b86c61d0a9533d3cfbdb29c0ff699e849)

Tester membership, external beta groups, App Store review submissions and other
platform builds were not changed.

Upload/build ID: `70b4f799-71d6-4737-8d90-e1db208a3fc0`.
IPA SHA-256:
`eae02522d94b6d6b89bd82185b05e49ca94602217e4df9bf5d6e5cd1f0f4543f`.

Signed archive, IPA, package checks, Apple receipts and delivery snapshots:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/preview-swipes-1.2-12-20261023/`.

Native swipe evidence:
`/Users/brad/Documents/Codex/2026-10-23/pulsecanvas-preview-swipes-review/`.
Native onboarding/Radio layout evidence:
`/Users/brad/Documents/Codex/2026-10-23/pulsecanvas-ipad-onboarding-review/`.
