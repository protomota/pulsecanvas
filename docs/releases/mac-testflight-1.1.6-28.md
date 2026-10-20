# Mac TestFlight 1.1.6 (28) — Radio audio compatibility candidate

> **Reverted — October 20, 2026.** This upload receipt is historical. The candidate’s audio changes were subsequently reverted at the owner’s request after a restart cleared the reported crackling. The uploaded binary is unchanged by that source rollback.
> See [rollback details](../development/audio-investigation-rollback.md).

[Open build in App Store Connect](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/4baa2886-77cb-4b37-b062-1bd8be9ae3b0)

Available to the existing internal TestFlight group on October 20, 2026. Archived
from [source 8a9d033](https://github.com/protomota/pulsecanvas/commit/8a9d0333a8ed39eb03df74bfe3fa33b5aedb8be4),
committed and pushed before packaging.

Mac Radio uses AVPlayer for continuous music playback to test compatibility with
the USB DAC crackling reported in build 27. iPhone/iPad retain their working
AVAudioPlayer path. Studio retains its precise section loops, with the preceding
idle hardware release fix included. See [implementation and test results](../development/mac-radio-media-player.md).

## Verified delivery

- Audio and Radio suites, real-file AAC/MP3/WAV/FLAC transport probes, Mac Debug
  compilation and iOS simulator compilation passed. Rapid seek revisions, clock
  progression, pause/resume, completion ownership, song advance, folder looping
  and return to Studio are covered. These are not an audible DAC verification.
- Release archive and distribution export passed. The actual expanded signed
  installer payload passed the store artifact validator: version/build, team,
  distribution signing/profile, sandbox, legal/privacy, exact soundtrack and
  native shader resources. It contains 336 active Metal effects and no external
  engine, OpenGL presets or Sparkle.
- Apple validation and upload succeeded with no errors. Fresh API reads verify
  version 1.1.6, build 28, platform MAC_OS, processing `VALID`, internal testing
  `IN_BETA_TESTING` and exact English tester notes.
- The existing internal group retains its previous 42 builds, for 43 total.
  No tester, access or external beta-review changes were made.
- Before/after snapshots confirm every public version's review state and
  selected build are unchanged. No website or Creators release was published.
- The running installed Mac app was not replaced or restarted. Original music,
  copied music folders, projects, presets and device routing are unchanged.

The owner must install build 28 through TestFlight and listen to affected passages
through the DX3 Pro+ before this issue can be marked resolved. Clean output on the
affected DAC is **not yet confirmed**. No broad fix claim follows from processing
or transport tests passing.

Local evidence, excluded from Git:
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mac-1.1.6-28/`.
Includes archives, signed export, expanded payload, hashes, Apple logs, tester
notes, API snapshots and delivery receipt.
