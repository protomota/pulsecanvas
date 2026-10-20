# iPhone and iPad TestFlight 1.1.5 (5)

Uploaded and enabled for the existing internal tester group on October 20, 2026.

- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/75e13072-f762-4306-895f-03f9f9e7a8df)
- [Application source](https://github.com/protomota/pulsecanvas/commit/e7b537a810e697871538a531e17b382c4e0534c6)
- [Landscape Radio layout](../mobile-radio-landscape.md)

On iPadOS 26 and later, the custom header reserves 28 additional points above its
buttons. Studio and Radio remain left-aligned below the system window-control
strip; Library and Project actions remain on the right. iPhone and earlier iPadOS
header positions are unchanged. This build also includes the preceding landscape
Radio change: the preview fits the remaining height and all controls remain
visible without a vertical ScrollView.

## Verification

- Final simulator build and iPad UI command passed with normal `TEST SUCCEEDED`
  and exit 0. The test ran on iPad mini (A17 Pro) and iPad Pro 13-inch (M5), both
  iOS 27, with one pass and zero failures on each. The finalized xcresult confirms
  those results. Assertions cover left-aligned, hittable tabs below the reserved
  strip in both orientations, all Radio controls on-screen, no landscape scroll
  container, fallback messaging, and uninterrupted playback through rotation.
- The final iPhone 17 Radio regression suite passed with zero failures, covering
  playback, pause, seeking, empty favorites and stable heart/button placement.
  Its xcodebuild process stalled in post-suite cleanup and was terminated after
  the complete passing suite was logged; a normal iPhone command exit is not
  claimed.
- Final Release archive, manual App Store distribution export, strict signature,
  provisioning team/app ID and actual IPA resource checks passed. The package is
  1.1.5 (5), supports both device families, and includes 336 native effects with
  source-matched catalog, shaders, soundtrack, legal and privacy resources.
  Background audio is present; external presets/engine, Sparkle and mobile Debug
  launch fixtures are absent.
- Apple validation finished successfully after a transient server 500 recovered
  automatically. Upload succeeded and processing reached `VALID`. Fresh API reads
  confirm platform `IOS`, version 1.1.5, build 5, `IN_BETA_TESTING`, and the exact
  English tester notes.
- Only build 5 was added to the existing internal group. All 35 prior builds are
  retained; the group now contains 36 builds. Existing public version states and
  Mac/Vision review build selections match the before-upload snapshots.
- `git diff --check` passed. Source was committed and pushed before upload. A
  locally signed right-aligned candidate was superseded after the user's layout
  correction and was never uploaded.

Physical iPad floating/resized windows, locked-device playback and Bluetooth
controls remain tester checks. The simulator checks establish layout bounds,
not the presence of actual physical-device window controls. Existing SDK runtime
warnings about synchronous audio activation and internal QoS waits remain.

Local evidence, outside Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-1.1.5-5/`

- Final archive: `PulseCanvasMobile-final.xcarchive`
- Uploaded IPA: `export-final/PulseCanvas Studio.ipa`, 11,081,844 bytes
- SHA-256: `5f86b5ae1e53508548d7a46ee7a13a974b412e92ce94004387d8a454b7cfe286`
- Delivery/build ID: `75e13072-f762-4306-895f-03f9f9e7a8df`
- Finalized iPad xcresult, extracted attachments, artifact/delivery receipts,
  logs, tester notes and before/after API snapshots are preserved locally.
