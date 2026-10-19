# Vision Pro 1.1.5 (11) — version alignment

Released to the existing internal TestFlight group on October 19, 2026.

- [Vision Pro 1.1.5 (11)](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/95d1c020-eb58-40f0-9f05-9fab9937bb25)
- [Mac 1.1.5 (24)](https://appstoreconnect.apple.com/apps/6821642700/testflight/macos/9852df8c-214f-43f4-b343-572390b96371) remains available.
- Source: [b5e0c49ed9d3bd8760ae999c6acd0baeda2ee35b](https://github.com/protomota/pulsecanvas/commit/b5e0c49ed9d3bd8760ae999c6acd0baeda2ee35b), pushed to `main`.

Both platforms now read `MARKETING_VERSION` from the shared root
`Version.xcconfig`. Build numbers remain independent in each platform's
`Release.xcconfig`. Creators/local packaging, source packaging and distribution
verifiers read that same shared version. Future release-version changes belong
in the shared file.

The editable Vision Pro App Store Connect draft was changed from 1.0 to 1.1.5,
then read back as `PREPARE_FOR_SUBMISSION`. The API key could read but not edit
that draft; the existing signed-in owner session saved the version through the
normal App Store Connect UI. It was not submitted for review. Mac 1.1.4 remains
`WAITING_FOR_REVIEW`. No build was expired or removed.

The new Vision Pro IPA contains the same features as 1.0 (10). Apple validation
and upload succeeded without errors; processing completed `VALID`. Fresh API
reads confirmed `IN_BETA_TESTING` for Vision 11 and Mac 24, exact English tester
notes, and access for the existing PulseCanvas Mac Beta internal group. The group
now has 27 builds, with all 26 previous builds retained. External beta review was
not submitted.

## Verification

- Xcode resolves Mac to 1.1.5 (24) and Vision Pro to 1.1.5 (11).
- All 20 provenance regression tests pass. Modified shell scripts pass syntax
  checks; modified Python verifiers compile.
- A generated committed-source archive includes the exact shared version file
  and both platform configurations. Its versioned name still uses the independent
  Mac build number, as expected for the Mac source-packaging script.
- The existing signed Mac 24 payload still passes the updated version validator,
  including sandbox, architecture and native-only resource checks.
- Vision device archive/export pass. The actual signed IPA passes version/build,
  icon, resource, signature, team/profile and native-only checks: 336 native
  effects, with no external engine or catalog. Its embedded version is 1.1.5 and
  build number is 11.
- No Swift application behavior changed; simulator interaction and physical-device
  installation tests were not repeated for this version-only update.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/1.1.5-11/`

- IPA: `vision-export/PulseCanvas Vision.ipa`, 10,760,490 bytes
- SHA-256: `c80bc5888fa61305a295f289c7910019c0801093e8da55ab3d30e7e8aa5a1655`
- Artifact receipt, archive/export/Apple logs, source-package check, editable-draft
  before/after snapshots, testing states, exact notes, group snapshots and
  screenshots remain local and excluded from Git.
