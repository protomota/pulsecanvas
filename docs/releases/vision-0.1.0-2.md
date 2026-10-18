# Vision Pro 0.1.0 (2) — TestFlight

Delivered October 18, 2026 to the existing internal **PulseCanvas Mac Beta** group.
App Store Connect reports **VALID / IN_BETA_TESTING**. The tester notes were saved
and read back from the API. All previous builds remain assigned to the group.

- App record: `6821642700`
- Bundle ID: `com.protomota.pulsecanvas`
- Platform: `VISION_OS`
- Build ID: `b6cf8c35-e4d7-4e51-a1f9-30ca668d0048`
- Archived source: `affa3e5515f40d6356226ca9a6e03395a21cd4df`
- Feature changes: `3c47fb65823abaf777f2b8565aa83fde5470326b`
- Native effects: **336**; no projectM, community presets/textures or Sparkle.
- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/b6cf8c35-e4d7-4e51-a1f9-30ca668d0048)

## Changes

Looping defaults on and persists in Studio projects. The wider sidebar has
wrapping titles, one shared category/favorites filter, visualizer shuffle and
separate style dice. Radio has station selection, loading/retry states and
automatic next-track playback, using a separate session to preserve Studio data.

Full immersion hides the Studio window and the room. Floating controls can be
hidden/shown with a pinch; returning restores Studio. The immersive renderer
removes duplicate window-preview work, reuses geometry, limits GPU work in flight,
and adds an optional edge-smoothing pass. The icon package uses a full-bleed
background instead of an inset opaque square.

## Verification

- Project migration/defaults, actual audio loop boundaries, loop-off completion,
  preference persistence, filtered randomization and style independence: passed.
- Radio station/catalog fixtures, verified downloads, automatic next-track
  playback and preservation of the Studio file: passed.
- Metal presentation filter flat-color, disabled-output, diagonal-edge, bounds
  and alpha checks: passed.
- visionOS simulator/device compilation and Apple TV shared-transport regression
  compilation: passed. The simulator installs and displays the Studio preview.
- Exported IPA: strict Apple Distribution signature, matching profile, exact
  native shader/audio resources, legal/privacy files and compiled icons: passed.
- Apple package validation and upload: succeeded without errors. Processing
  completed and the build is available for internal testing.

Physical-headset frame rate, shimmer reduction, gaze/pinch behavior, immersive
entry/exit and the icon's TestFlight appearance still require headset testing.
MP4 export and Mac project interoperability are not included.

Mac version 1.1.4 remains **WAITING_FOR_REVIEW**; this delivery did not withdraw,
replace or submit a public App Store version. Apple TV and website releases were
not changed.

## Local delivery evidence

Artifacts remain outside Git under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/0.1.0-2/`:

- `vision-export/PulseCanvas Vision.ipa`: **10,189,180 bytes**
- IPA SHA-256: `6198c779b8f89d6e40853896a3355b3d10335cb71c0f0d26fb799878b2fe5134`
- `vision-delivery-receipt.json`, `vision-testflight-final.json`,
  `vision-group-final.json`, and `logs/vision-*`

Feature test logs and the simulator layout screenshot are in the sibling
`Vision-UI-2026-10-18` directory.
