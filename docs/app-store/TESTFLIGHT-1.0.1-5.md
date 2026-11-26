# TestFlight preparation — 1.0.1 (5)

Superseded by [build 6](TESTFLIGHT-1.0.1-6.md), which defers the support and review prompts until the second successful video save. Build 5 was not uploaded.

Prepared on 2026-10-12. **Upload is blocked by expired Xcode Apple-account authentication. This build is not confirmed available in TestFlight.** The browser App Store Connect session also requires sign-in. No public version, submission, tester access or beta-group assignments were changed. The owner reports an existing public submission in review; its live status could not be verified during preparation.

Source: `18228d624470eb1911f659008b2c14f80a779579`, pushed to `codex/mac-app-store-preparation`.

Includes the styled first-successful-export thank-you sheet, optional sharing/feedback actions, `/tips` link for eligible storefronts, and one StoreKit rating request after dismissal. Store builds show the external tip action only for the actual U.S. Apple storefront; unknown/other storefronts omit it. Apple decides whether its rating prompt appears; it is suppressed in TestFlight. Renderer/resource identifiers and engineering notes were normalized without changing GPU output. The current bundled soundtrack, project settings, presets and user session were preserved.

Validation: signed archive and distribution app passed arm64, bundle/version/build, sandbox, provisioning-profile, resources, strict app/library signature and installer certificate-chain checks. Store-build support-policy and once-only persistence checks passed; actual saved/canceled/failed export-hook validation and GPU equivalence checks are recorded in the ignored local validation folders. The distributed MP3 matches SHA-256 `8c863f65e8db705ab4003a2af6df15cf336bdbf92277ee981b5922b107dce8f7`.

Artifacts:
- Signed archive: `build/app-store/PulseCanvas-1.0.1-5.xcarchive`.
- Signed distribution package: `build/app-store/export-1.0.1-5/PulseCanvas Studio.pkg`.
- Committed-source snapshot: `build/app-store/PulseCanvas-1.0.1-5-source.tar.gz`, SHA-256 `b07d6befd0815940e7d6aaea02b87c71a05a47f67dff7985dd652c430e295d43`.
- Checks and failed upload receipt: `work/testflight-1.0.1-5/` (local, ignored).

Resume after the existing Apple account signs back into Xcode and App Store Connect. Verify the latest live build number, retry the archived build upload, wait for Apple processing, save What to Test notes, and assign only the existing **PulseCanvas Mac Beta** internal group. Preserve the public submission in review.

- Build list: https://appstoreconnect.apple.com/apps/6821642700/testflight/macos
- Existing beta group: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/groups/e06555d7-c301-4fd1-9ab3-572521a25ba6
