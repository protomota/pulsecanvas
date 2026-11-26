# iPhone and iPad TestFlight 1.1.5 (4)

Uploaded and enabled for the existing internal group on October 20, 2026.

- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/9117d0f3-c304-4056-9334-e78b3e1f08aa)
- [Application source](https://github.com/protomota/pulsecanvas/commit/3cb0f80ca1b85b2386a17a6e3f0f4178ae9a1f16)
- [Implementation, test results and limitations](mobile-export-background-2026-10-20.md)

This build fixes the Export MP4 menu restriction for loaded Radio songs, pins
Render and Save actions for small screens, enlarges Library/Radio randomizer
dropdowns, and enables background listening with native playback controls.
Full-screen Radio includes Next song, and mobile presentation always fills the
display without a Fit control. Projects and saved preferences are retained.

## Release verification

- Device archive and manual App Store distribution export succeeded. Strict
  code signature, team, app ID and distribution-profile checks passed.
- The final signed IPA passed resource checks: 1.1.5 (4), iPhone and iPad,
  iOS 18 minimum, background audio, 336 native effects, matching source resources,
  and no external preset engine, updater or Debug fixtures.
- Apple validation and upload succeeded with no errors. Delivery status is
  `VALID` and uses-non-exempt-encryption is false.
- Fresh API reads confirm platform `IOS`, version 1.1.5, build 4, processing
  `VALID`, internal state `IN_BETA_TESTING`, and the exact English tester notes.
- Only this new build was added to the internal tester group. All 34 previous
  group builds were retained; it now contains 35 builds.
- Existing public version states and Mac/Vision review build selections match
  the saved before-upload snapshots. No public review submission was replaced.
- Source was committed and pushed to `main` before upload. Distribution products,
  account readbacks and user data remain outside Git.

Both targeted UI tests passed on both iPhone 17 and iPad Pro 13-inch simulators,
including actual rendering and native Files saves. Shared Radio smoke tests
passed. Xcode's post-suite cleanup limitations and physical-device checks not
run are recorded in the linked validation report; simulator background playback
checks do not establish locked-device or Bluetooth behavior on real hardware.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-1.1.5-4/`

- Final archive: `PulseCanvasMobile-final.xcarchive`
- Uploaded IPA: `export-final/PulseCanvas Studio.ipa`, 11,063,384 bytes
- SHA-256: `72969ea768246fb4b04e9900c4a25e3e69363c18e6b22bf758312f3f06541352`
- Delivery/build ID: `9117d0f3-c304-4056-9334-e78b3e1f08aa`
- Artifact and delivery receipts, final logs, extracted payload, tester notes,
  before/after group snapshots and API readbacks are local and excluded from Git.
