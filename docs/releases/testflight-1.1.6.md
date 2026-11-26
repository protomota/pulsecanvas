# TestFlight 1.1.6 — Studio music and personal Radio folders

Available to the existing internal TestFlight group on October 20, 2026.
All three packages use [source 1bb350f](https://github.com/protomota/pulsecanvas/commit/1bb350f352c5f962fe31c97c3068836b01ec19b7), committed and pushed to main before archiving.

| Platform | Version (build) | TestFlight |
|---|---|---|
| Mac | 1.1.6 (26) | [Open build](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/b069daa4-a365-4883-acab-3cfb4fa5781a) |
| iPhone / iPad | 1.1.6 (6) | [Open build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/09b85854-46fd-463a-94df-49e53d9c2282) |
| Apple Vision Pro | 1.1.6 (14) | [Open build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/a8d14824-2205-469a-811c-76ed6b2f733e) |

Studio can choose a catalog song, search, filter favorite songs, and use it as a
single soundtrack for the existing timeline and MP4 export. Radio can copy an
album or folder, including subfolders, and continuously play its songs in order
or on shuffle. The personal collection persists locally and remains separate
from Studio's catalog picker and catalog-song favorites. Leaving Radio restores
the Studio soundtrack. See [implementation and test details](../development/1.1.6-personal-radio.md).

## Verification

- Release archives and App Store distribution exports passed for all three
  platforms. The Mac's initial manual-signing archive attempt failed because its
  cached profile is Xcode-managed; the automatic archive and automatic
  distribution export passed using the existing signing setup.
- Actual exported IPAs and the expanded Mac installer payload passed signature,
  team/profile, version/build, legal/privacy, soundtrack and native-resource
  checks. All contain 336 active Metal effects; external engines, OpenGL presets
  and Sparkle are absent. Mobile Debug fixture flags are absent from Release.
- Apple validation and upload succeeded with no errors for every package. Fresh
  API reads verify the expected platform/version/build, processing `VALID`,
  internal testing `IN_BETA_TESTING`, and exact English tester notes.
- All three builds belong to the existing internal group. Its previous 36 builds
  remain present, for 39 total. No external beta-review submission was made.
- Before/after snapshots confirm all public App Store version states and selected
  builds are unchanged, including the Mac and Vision 1.1.5 review submissions.
- The preceding implementation passed shared Radio and Vision transport tests,
  iPhone/iPad native UI tests, and platform compilation. Subsequent source changes
  before these archives were version/build settings and documentation only.
  Physical-device folder providers, large real-world albums and manual Mac/Vision
  folder-picker flows remain TestFlight checks; no new physical-device testing
  is claimed.
- No website, Sparkle feed, public App Store release or Apple TV build was changed.

Local evidence, excluded from Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/1.1.6/`
This contains archives, exports, extracted payloads, artifact hashes, validation/
upload logs, tester notes, final delivery receipts and before/after API snapshots.
