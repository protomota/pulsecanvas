# TestFlight 1.1.6 — Radio playback update

> **Reverted — October 20, 2026.** This upload receipt is historical. The playback and cache changes were subsequently reverted at the owner’s request after a restart cleared the reported crackling. The separate personal-song favorite UI changes remain. Uploaded binaries are unchanged by that source rollback.
> See [rollback details](../development/audio-investigation-rollback.md).

Available to the existing internal TestFlight group on October 20, 2026.
All three signed packages were archived from
[source 83f23f7](https://github.com/protomota/pulsecanvas/commit/83f23f72705fc1e5c7c12a243750df260a1b137b),
committed and pushed to main before archiving.

| Platform | Version (build) | TestFlight |
|---|---|---|
| Mac | 1.1.6 (27) | [Open build](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/db0de48d-94bc-4ec2-9e3c-31d10faba96f) |
| iPhone / iPad | 1.1.6 (7) | [Open build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/c7ef8b05-0337-4ed9-899f-e387270c94bc) |
| Apple Vision Pro | 1.1.6 (15) | [Open build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/b4298cf2-0ade-424b-80f3-6fbda1751d3f) |

Radio uses an independent continuous audio player on Mac/mobile. Studio keeps
its precise section player, reconfigured while stopped. Cached tracks retain
their actual file extension; valid older cache entries migrate without
transcoding or changing the original audio. Personal songs have no song-favorite
heart or catalog-favorites shortcut. Catalog-song favorites and visualizer
favorites remain. See [implementation and test details](../audio-radio-playback.md).

## Verified

- Audio, Radio and Vision transport suites passed, including end-of-song advance,
  queue looping, seeking, Studio handoff and legacy cache migration. Two iPhone
  simulator UI tests passed with zero failures, including background audio,
  full-screen transport and missing personal-song hearts. Mac and Vision Debug
  builds passed.
- Release archive and distribution export passed for all three platforms.
  Actual expanded Mac installer and extracted IPA payloads passed signatures,
  team/profile, version/build, legal/privacy, source soundtrack and native-resource
  checks. Each contains 336 active Metal effects, with no external engine,
  OpenGL presets or Sparkle. Debug fixture hooks are absent from mobile/Vision
  Release executables.
- Apple validation and upload succeeded with no errors for all three packages.
  Fresh API reads verify platform/version/build, processing `VALID`, internal
  testing `IN_BETA_TESTING`, and exact English tester notes.
- All three builds are in the existing internal group. Its previous 39 builds
  remain, for 42 total. No external beta-review submission was made.
- Before/after API snapshots confirm public App Store version states and selected
  builds are unchanged, including the Mac/Vision 1.1.5 review submissions.
- Source changes and build counters were committed before archiving. Only this
  delivery documentation was added after packaging. Unrelated local marketing
  assets were left untouched.

## Remaining check

The owner's ongoing popping with personal-folder MP3/M4A files was not reproduced
using synthetic tones. Automated transport and UI checks do not establish an
audible fix on physical Mac/iPhone hardware. Please replay the affected songs
in these builds, including seeking, skipping, looping and returning to Studio.
No physical-device audible verification is claimed.

No website, Creators release, Sparkle feed, public App Store submission or Apple
TV build was changed.

Local evidence, excluded from Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/1.1.6-audio-fix/`
Includes archives, exports, extracted payloads, hashes, Apple validation/upload
logs, exact tester notes, final delivery receipt and before/after API snapshots.
Implementation-test evidence:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Development/audio-folder-fix/`.
