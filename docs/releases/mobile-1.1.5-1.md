# iPhone and iPad TestFlight 1.1.5 (1)

Uploaded and enabled for the existing internal TestFlight group on October 19,
2026. The marketing version matches Mac and Vision Pro; the independent iOS
build number is 1.

- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/3a5e2469-118e-48e6-85f7-070325ea7920)
- [Application source](https://github.com/protomota/pulsecanvas/commit/778a4eac627c39281f8c14c5aefbf53ea4f6a692)
- Apple build/delivery ID: `3a5e2469-118e-48e6-85f7-070325ea7920`

This initial universal iPhone/iPad build includes 336 native Metal effects,
responsive Studio and Radio, favorite looks/songs, project exchange, presentation
and MP4 export. See [implementation and simulator checks](mobile-foundation-2026-10-19.md).

## Release verification

- Device archive and distribution export succeeded. Automatic export first
  failed because this API key cannot use Apple's cloud-managed signing. Manual
  export succeeded using the existing local Apple Distribution certificate for
  Protomota, LLC and existing App Store profile. The profile's name mentions
  Vision, but its decoded supported platforms include iOS, xrOS and visionOS;
  its bundle ID, team and signing certificate match this app.
- Actual extracted IPA passes strict code-signature verification. Both its
  signed entitlements and distribution profile have `get-task-allow=false`
  and `beta-reports-active=true`, with the correct application/team identifiers.
- Artifact checks confirm version/build 1.1.5 (1), device families 1 and 2,
  minimum iOS 18, 336 effects, matching catalog/shader/soundtrack/license/privacy
  resources, no external preset/engine/updater assets or linkage, and no Debug
  QA launch hook. Checks were run against the exported IPA, not only the archive.
- Apple validation and upload succeeded with no errors. The first validation
  attempt correctly reported that the iOS platform was missing. The iOS draft
  platform was added in App Store Connect and set to 1.1.5, then validation passed.
- Fresh API readbacks confirm processing `VALID`, platform `IOS`, marketing
  version 1.1.5, build 1, internal state `IN_BETA_TESTING`, and the exact saved
  English tester notes. Only the new build was added to the existing internal
  group; all 28 previous group builds remain (29 total).
- Mac and Vision Pro version IDs and `WAITING_FOR_REVIEW` states were unchanged
  before and after this release. No public App Review or external beta submission
  was made. No old build was expired or removed.

Physical-device installation, performance, sustained 4K60 export and actual
Files-provider save completion remain unverified. The prior simulator UI and
real decoded MP4 checks are documented separately; this release did not repeat
those suites.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-1.1.5-1/`

- IPA: `export/PulseCanvas Studio.ipa`, 11,014,949 bytes
- SHA-256: `dbbb5acb8447bc6a24110e47743375385aa0cfe2bcb8203f54476a47b22eb09a`
- Archive, export options, logs, extracted payload, artifact receipt, tester notes,
  group snapshots and App Store Connect state readbacks remain outside Git.
