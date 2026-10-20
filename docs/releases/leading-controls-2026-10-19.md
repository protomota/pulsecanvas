# Stable favorite and playback controls — October 19, 2026

Application source: [2ec5b30](https://github.com/protomota/pulsecanvas/commit/2ec5b30486a0).
Source-package repair: [b038e98](https://github.com/protomota/pulsecanvas/commit/b038e98).

Hearts now precede the current visualizer and Radio song titles on iPhone,
iPad, Mac and Vision Pro, including immersive Vision controls. Apple TV's
visualizer heart also precedes its name. The Mac header uses a fixed icon-only
favorite control with an accessible Favorite/Unfavorite label. Transport buttons
use slightly wider fixed label frames so Play, Pause and Radio loading states
occupy the same width. Existing library rows with fixed trailing controls retain
their layout.

## Delivered to TestFlight

All four uploads passed Apple validation and upload without errors, processed
`VALID`, and were verified `IN_BETA_TESTING` in the existing internal group.
English tester notes were saved and read back. All previous group builds were
retained. No tester access, external beta review or public review was changed.

| Platform | Version (build) | Build |
|---|---|---|
| iPhone/iPad | 1.1.5 (3) | [cfcf7afb](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/cfcf7afb-6dba-47d4-98af-b28b341ec404) |
| Mac | 1.1.5 (25) | [9a2fd770](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/9a2fd770-4f15-439e-8c21-efddaf9a26da) |
| Vision Pro | 1.1.5 (13) | [c9739bcd](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/c9739bcd-2d47-48cc-a57d-28ff586a7683) |
| Apple TV | 0.1.0 (3) | [aeb974ad](https://appstoreconnect.apple.com/apps/6821642700/testflight/tvos/aeb974ad-257d-4807-8b13-eea3c56014df) |

Mac and Vision Pro public submissions remained 1.1.5 `WAITING_FOR_REVIEW`;
iOS 1.1.5 and tvOS 1.0 remain drafts, matching the pre-delivery state.

## Verification

- iPhone and iPad Studio UI tests passed: leading heart, unchanged heart origin
  after selecting another title, Play/Pause width equality, controls/presentation
  and actual eight-second MP4 rendering.
- iPad Radio UI test passed: loading, playback, seek, empty-favorites fallback,
  fixed heart origins after randomization and fixed playback width. The first
  geometry check ran before asynchronous song loading finished; it was moved
  after the existing seek-ready expectation and passed on rerun.
- Vision Pro Radio UI test passed, including leading visualizer/song hearts,
  aligned song controls, playback and visualizer changes.
- Mac Studio and Radio were inspected in an isolated, separately identified
  local app. Playback was stopped after inspection. User projects/preferences
  were not replaced. Apple TV compiled; no physical TV interaction test is claimed.
- All final exported IPAs and the expanded Mac PKG passed resource/source,
  strict signature and native-only checks. Mobile Release fixture markers were
  absent. Platform versions/builds and device families matched the intended values.
- Source archive packaging now includes the mobile target, and provenance
  verification includes the shared version file. The final archive passed full
  committed-input verification against b038e98.

## Website Mac download — pending local keychain interaction

The updated Creators app compiled, but Developer ID signing is waiting at a
macOS SecurityAgent prompt for codesign. Computer Use explicitly blocks access
to that security dialog. The owner was asked to enter their Mac/keychain password
and click Allow. No signed installer was published; website/appcast still point
to 1.1.5 (23). Existing App Store reviews were not withdrawn.

Continue the owned signing process, package/notarize/staple/verify the DMG,
sign its Sparkle update, upload the installer plus verified matching source,
and update website release metadata/appcast only after those checks pass.

Local artifacts, logs, API receipts, screenshots and the verified source archive:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/leading-controls-20261019/`.
The source archive ending `b038e98a12e4-source.tar.gz` is verified; the earlier
2ec5b30 source-package attempt is superseded. No signing keys or private local
artifacts are committed.

## Website update canceled — October 20, 2026

The owner chose “Skip the website download update” after resuming signing.
The owned signing process was stopped. No DMG, website metadata, appcast or
production deployment was published. The four TestFlight deliveries above remain
available; this cancellation does not withdraw any build or review. The current
website installer remains 1.1.5 (23).
