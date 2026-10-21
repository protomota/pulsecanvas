# iOS 1.2 (8) release — October 21, 2026

Source commit: `787e889` (palette accents, current Duo workspace and all earlier
mobile fixes). The existing untracked 1.1.5 marketing artwork is preserved.

## Signed artifact

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-1.2-8/`

- Release archive and App Store Connect export: passed.
- Strict/deep codesign verification: passed on the archive and exported IPA.
- Archive and actual extracted IPA resource verification: passed, 336 native
  effects matching this checkout, exact shader/catalog/music/license/privacy
  resources, background audio entitlement, iPhone/iPad support and iOS 18 minimum.
- No external visualizer engines, OpenGL preset packs, updater or Debug QA
  fixture hooks in the packaged app. Distribution profile has debugging disabled.
- Uploader accepted the 11,258,874-byte IPA without errors. Delivery UUID:
  `cafe64d2-4d27-4f0e-beed-bb239dec707b`.
- Previous simulator usability/regression checks and the 1,680-output palette
  check are recorded in the development notes. Physical-device validation of
  this exact distribution artifact has not been performed.

The artifact folder holds the actual IPA, archive, distribution/signing logs,
resource check receipts and SHA-256/source provenance. These remain outside Git.

## Listing

“Optimized for iPhone Duo” is saved in the promotional text and description,
including the larger preview, full-width Studio timeline and adaptive controls.
Fresh official API reads verified the exact saved copy. Apple exposes no separate
What's New field for this first iOS release (`whatsNew` is null); the prepared
release-note text is retained in `mobile-1.2.en-US.json` for TestFlight notes.

All 18 current-layout screenshots (six each for iPhone, Duo and iPad) retain their
verified ACTIVE placements and prepared image states. Header/search assets and
other platforms are preserved.

## Delivery status

Apple processing: **VALID**. Build 1.2 (8) is **IN_BETA_TESTING** in the existing
internal group **PulseCanvas Mac Beta**, which also contains the previous iOS
builds. No new testers or groups were created. The exact prepared Duo release
notes were saved as the build's English What to Test text and verified by API.

App Review: **WAITING_FOR_REVIEW**, submitted October 21, 2026 at 7:32 PM EDT.
The App Store version is attached to this exact build, verified through a fresh
API read and the visible review details page. Submission ID:
`e5843375-c3e5-412e-bd0b-c3fa84836bb6`.

The existing automatic-release-after-approval setting is retained. Submission
is not approval or public availability. The existing Mac review submission
`ee3c9e5f-5df2-44de-b920-a51c3bee99c7` remains unchanged, Waiting for Review.

- [App Review submission](https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/e5843375-c3e5-412e-bd0b-c3fa84836bb6)
- [TestFlight build](https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/ios/cafe64d2-4d27-4f0e-beed-bb239dec707b)

The existing API key can manage beta notes and existing-group build membership;
it cannot change the App Store build selection. That selection and the final
submission were completed through the signed-in browser. No credentials or
permissions were changed.
