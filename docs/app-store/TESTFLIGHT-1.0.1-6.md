# Review replacement preparation — 1.0.1 (6)

Superseded by [build 7](TESTFLIGHT-1.0.1-7.md), which also includes the updated first-party license. Build 6 was not uploaded.

Prepared on 2026-10-12. **Signed and validated locally; upload and review replacement remain blocked by Apple-account sign-in.** This candidate supersedes build 5. No App Store submission has been withdrawn or replaced by this preparation.

The owner explicitly authorized withdrawing the submission currently in review and replacing it with this updated build. Do not ask for that authorization again. Restore the existing account's Xcode and App Store Connect sessions, upload the replacement, wait for processing, replace the current review build and resubmit. Verify the live public version before associating the replacement; App Store Connect version and binary marketing version must match. Keep existing metadata, screenshots, manual-release choice and beta tester access. If matching version changes are required, record them and build/sign the matching binary. No final public release is authorized by this request.

Source: `657345ee6aab26c8e4ee03f59d2789e7bd2f0cd1`, branch `codex/mac-app-store-preparation`.

Behavior: the first successful video save shows only its existing saved-video confirmation. The second successful save makes the styled thank-you sheet eligible, after the success toast finishes and the app is active without another sheet. Its dismissal makes one StoreKit review request; Apple decides whether the system review dialog appears and suppresses it in TestFlight. The count survives relaunch, canceled/failed exports do not count, and later exports do not repeat the prompt. Earlier installations with one saved-video milestone migrate to count one; existing dismissal/review history suppresses repetitions. The eligible storefront `/tips` behavior from build 5 is retained.

Validation: portable and Store-build milestone tests passed, covering second-save eligibility, relaunch, concurrent windows, one review attempt, upgrade history and storefront policy. Actual audio-inclusive 720p, portrait 4K and landscape 4K exports passed, triggering eligibility only on success number two. Canceled and failed renders did not count or replace an existing file. Signed archive/distribution validation passed bundle/version/build, arm64, narrow sandbox, profile, app/library signatures, resources and installer certificate-chain checks.

- Signed archive: `build/app-store/PulseCanvas-1.0.1-6.xcarchive`.
- Distribution package: `build/app-store/export-1.0.1-6/PulseCanvas Studio.pkg`.
- Committed-source snapshot: `build/app-store/PulseCanvas-1.0.1-6-source.tar.gz`; SHA-256 `59235013e39d698160747383a043e03b9a51c46d5b43d8c20da00f5b2e029d77`.
- Logs/receipt: `work/testflight-1.0.1-6/` (local, ignored).
- Existing public submission: https://appstoreconnect.apple.com/apps/6821642700/distribution/macos/version/inflight
- TestFlight builds: https://appstoreconnect.apple.com/apps/6821642700/testflight/macos
- Existing internal group: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/groups/e06555d7-c301-4fd1-9ab3-572521a25ba6

Apple's replacement workflow: https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/remove-a-submission-from-review and https://developer.apple.com/help/app-store-connect/manage-builds/choose-a-build-to-submit . Live withdrawal, processing and resubmission must be verified before claiming completion.
