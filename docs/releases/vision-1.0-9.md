# Vision Pro 1.0 (9) — TestFlight

Delivered October 19, 2026. Apple verified **VALID / IN_BETA_TESTING** for build
`a2e55dbf-2a31-4509-9061-043042698f85`. The existing **PulseCanvas Mac Beta** internal
group has access. All 23 previous group builds were retained (24 total), and the
English tester notes were read back exactly.

- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/a2e55dbf-2a31-4509-9061-043042698f85)
- Archived source: `d2dad0a8057b71092b49d725a11347062df34393`, on `main`
- Version 1.0; build 9; bundle `com.protomota.pulsecanvas`; 336 native Metal effects

## Included changes

The info button opens Ratings & Support with large Rate on the App Store,
Tip the Developer, Share PulseCanvas and Send Feedback cards. The actual Apple
storefront controls tip-link availability, following the Mac policy; unknown
storefronts do not enable the link. Legal & Credits retains the LLC credit,
license and GitHub source link. Click checkmarks are local button history,
not evidence of a completed review, payment or share.

A second distinct successfully saved video enables the one-time native StoreKit
review request after the export sheet closes and the editor is active and idle.
Saving another copy of one render does not count twice; a canceled or failed
save does not count. Leaving a fourth Radio session shares the same one-time
request. Playback and immersion are not interrupted. **Apple suppresses native
review requests in TestFlight**; testers can still use the explicit App Store
review link. No custom automatic rating nag is shown in this Store edition.

Immersive controls use one horizontal row with separate song, visualizer and
viewing groups. Song and visualizer hearts have distinct labels; paused controls
remain visible, and Edge smoothing is in Viewing settings.

## Verification

- Shared engagement tests passed for Store and direct builds, including save
  milestones, persistence, duplicate saves and one-time native request policy.
- Save-file checks passed, including repeated copies, identical-content new
  renders, cache recovery, atomic replacement and failed-input preservation.
- Vision support UI suites passed with zero failures; the final screenshot
  repeat passed in 50.362 seconds. Xcode stalled after suite completion, and the
  runner was interrupted. This does not claim a normal test-command exit.
- Release simulator build passed; a real isolated render/Files-save capture
  test separately completed with `TEST SUCCEEDED` and the “Video saved” result.
- Release device archive and distribution export passed. The actual IPA passed
  native resource, legal/privacy, version/platform, provisioning profile and
  strict code-signature checks. Debug capture flags are absent from its executable.
- Apple validation and upload succeeded with no errors. Processing completed;
  the API confirmed Vision OS 1.0 (9), internal availability, exact tester notes,
  group membership and preservation of all previous group builds. An API group
  assignment timed out; App Store Connect's UI completed the assignment, which
  was confirmed by fresh API reads.
- Physical-headset testing and completed external rating/payment/share actions
  remain unrun.

Mac **1.1.4 remains WAITING_FOR_REVIEW**. No public App Review submission, external
beta submission, website deployment or new tester invitation was made.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/1.0-9/`

- Signed IPA: `vision-export/PulseCanvas Vision.ipa`, 10,737,316 bytes
- SHA-256: `1bd90af1af4d4988cf565582899a9ba276460de5680dad68f7e3a21775e38d96`
- Archive/export/Apple logs, payload verification, processing/group snapshots,
  exact notes, App Store Connect screenshot and `delivery-receipt.json` remain local.
