# iPhone and iPad TestFlight 1.1.5 (2)

Uploaded and enabled for the existing internal group on October 19, 2026.

- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/ios/47e88949-8b8b-43e2-99c1-e8ccc7d0669f)
- [Application source](https://github.com/protomota/pulsecanvas/commit/14e3e8b786c853936d170fde18f081eb35989210)
- [Implementation and validation](radio-empty-favorites-2026-10-19.md)

Includes empty-visualizer-favorites fallback, an explanatory Radio status,
catalog-error-only Retry, Radio Play/Pause and scrubbing, Studio active-card
centering, and sequence continuation when shorter bars append new cards.
Saved preferences, favorite looks, existing scenes and project styles are retained.

## Release verification

- Final device archive and manual distribution export succeeded. Strict code
  signature and App Store provisioning-profile checks passed for Protomota, LLC.
- Actual final IPA resource checks passed: version 1.1.5, build 2, iPhone+iPad,
  iOS 18 minimum, 336 native effects, matching shader/catalog/soundtrack/legal/
  privacy resources and no external engine/presets/updater. Both mobile Debug
  launch markers are absent. New fallback/card identifiers are present.
- Apple validation and upload both succeeded without errors. An earlier signed
  candidate passed validation before the later Studio requests arrived; it was
  superseded locally. Only the final candidate was uploaded as build 2.
- Fresh API reads confirm platform `IOS`, version 1.1.5, build 2, processing
  `VALID`, internal state `IN_BETA_TESTING` and the exact English tester notes.
- Only the new build was added to the existing internal tester group. All 29
  previous builds were retained; the group now has 30 builds.
- Mac and Vision Pro remain `WAITING_FOR_REVIEW` on their existing version IDs.
  Their new source changes compiled locally; no replacement binary, public
  submission or external beta submission was made for either platform.
- The new Studio-centering UI test also completed with normal `TEST SUCCEEDED`
  and command exit 0. Radio UI-suite cleanup limitations and physical-device
  checks not run are recorded in the linked validation receipt.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/mobile-1.1.5-2/`

- Final archive: `PulseCanvasMobile-final.xcarchive`
- Uploaded IPA: `export-final/PulseCanvas Studio.ipa`, 11,033,592 bytes
- SHA-256: `2988b118ee4eb6855cef7dee169d47ed9d6f0fcd1efdf0e38b162fa025d7547f`
- Apple delivery/build ID: `47e88949-8b8b-43e2-99c1-e8ccc7d0669f`
- `artifact-receipt-final.json`, final logs, extracted payload, tester notes,
  before/after group snapshots and API readbacks are local and excluded from Git.
