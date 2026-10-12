# Mac App Store release preparation

**Unresolved release hold recorded 2026-10-12:** [projectM's official licensing
guidance](https://github.com/projectM-visualizer/projectm/wiki/projectM-Licensing#apple-store-compatibility)
explicitly warns of incompatibility with Apple's stores, including macOS.
Dynamic linking, wrapper licensing and matching source do not resolve it.
Preset and texture permissions also remain independently unresolved. See
[LICENSES.md](LICENSES.md) and [RIGHTS-RESOLUTION.md](RIGHTS-RESOLUTION.md).
Historical submission/build evidence below does not establish licensing clearance.
This attribution update performs local engineering verification only.

Status: distribution build **1.0.0 (3) uploaded successfully**; Apple processing completed, build assigned to the internal Mac beta group and What to Test instructions saved. The App Store version remains attached to build 2. Listing text, four processed screenshots, live website URLs and age rating saved. Privacy responses and the functional public support page are published. Content-rights resolution, public corresponding source and beta validation remain pending. Owner chose to retain all effects. **Not submitted for App Review, approved, or live**. See [SUBMISSION-STATUS.md](SUBMISSION-STATUS.md) and [RIGHTS-RESOLUTION.md](RIGHTS-RESOLUTION.md).
Prepared on 2026-10-11. Branch `codex/mac-app-store-preparation`.

## Verified account

Apple Developer: Protomota LLC, organization, team **22HV69L32T**. Brad Dunlap is Account Holder. Membership renews 2027-03-23. The updated Developer Program License Agreement is verified accepted on 2026-10-11. Free Apps agreement shows Active (New Agreement Available). Paid Apps setup is unnecessary for this free app. DSA compliance shows Active.

- Account/agreement: https://developer.apple.com/account/
- Identifiers: https://developer.apple.com/account/resources/identifiers/list
- Apps: https://appstoreconnect.apple.com/apps
- Business: https://appstoreconnect.apple.com/business/
- Profiles: https://developer.apple.com/account/resources/profiles/list
- Certificates: https://developer.apple.com/account/resources/certificates/list

Registered explicit identifier: `com.protomota.pulsecanvas`, owned by team 22HV69L32T. Created macOS app **PulseCanvas Studio**, Apple ID **6821642700**, SKU `pulsecanvas-studio-macos`, English (U.S.). Version `1.0.0`, selected build `2`. Apple briefly reported that user access could not be saved and all users had access; full organization access was the intended setting.

- Version: https://appstoreconnect.apple.com/apps/6821642700/distribution/macos/version/inflight
- App information: https://appstoreconnect.apple.com/apps/6821642700/distribution/info
- Privacy: https://appstoreconnect.apple.com/apps/6821642700/distribution/privacy
- Pricing: https://appstoreconnect.apple.com/apps/6821642700/distribution/pricing
- TestFlight: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight

Saved description, promotional text, keywords, copyright, private Apple review contact/notes, no-sign-in and manual-release setting. Saved subtitle, Photo & Video primary / Music secondary categories, free pricing, availability in 175 territories, and 13+ age rating with regional variations. Domain **pulsecanvas.si** and public contact **support@pulsecanvas.si** confirmed by user. The production Vercel website and support/privacy pages load publicly. Marketing, support and privacy-policy URLs are saved in Apple. The support page now accepts bug reports at support@pulsecanvas.si; App Privacy responses are published. Public release source remains pending the full-effects rights resolution. Screenshot processing is tracked in SUBMISSION-STATUS.md.

## Build and signing

Xcode 27.0 / Swift 6.4, macOS 14 minimum, **Apple silicon only (arm64)**. Intel/universal is not supported by this prepared artifact. Existing SwiftPM development and portable builds remain available.

```sh
./scripts/store-release.sh test
./scripts/store-release.sh archive-unsigned
# After identifier/team verification and existing Xcode profile setup:
BUNDLE_ID_CONFIRMED=com.protomota.pulsecanvas ./scripts/store-release.sh archive
./scripts/store-release.sh export
```

The shared Xcode `PulseCanvas` scheme builds all native Swift files, recompiles AIR shaders, copies the real icon/resources/privacy manifest, and embeds/signs ProjectM before signing the enclosing app. Generated project regeneration: `python3 scripts/generate-store-project.py`. Build scripts run outside Xcode's build-script sandbox; **the shipped app remains sandboxed**. Hardened runtime and library validation remain enabled. No runtime network, microphone, or temporary sandbox exceptions.

- Isolated local signed test: `.build/store-test/Build/Products/Release/PulseCanvas Studio.app` (Apple Development signing; separate `com.protomota.pulsecanvas.storevalidation` container).
- Unsigned engineering archive: `build/app-store/PulseCanvas-Unsigned.xcarchive` (cannot upload).
- Signed archive: `build/app-store/PulseCanvas.xcarchive`.
- Distribution export: `build/app-store/export/`.

Installed certificates include Apple Development, Apple Distribution, and Developer ID identities. Private keys were not exported. A certificate being installed does not establish profile availability or successful distribution. Created Apple Distribution and Mac Installer Distribution certificates with explicit user approval via Xcode on 2026-10-11; private keys remain in Keychain. Existing installed distribution identity was revoked, another valid account certificate was not in this Keychain, and initial export lacked an installer identity and profile. Distribution export succeeded with automatic provisioning explicitly authorized for this run. The embedded Mac Team Store profile matches the identifier/team, has no device list or development debugging entitlement, and expires 2027-10-11. Strict app/library signature validation and installer certificate-chain checks passed. Apple accepted the Xcode upload at 11:10 EDT on 2026-10-11; server processing completed and build 1.0.0 (1) is available for internal testing. Upload warned that the ProjectM dylib dSYM is absent, limiting crash symbolication for that library. Developer ID notarization is a separate workflow.

## Release checklist

- [x] Preserve original running app and save project/preferences/playhead backup under `work/app-store/session-backup/`.
- [x] Verify active organization/team/role in personal Chrome.
- [x] Account Holder accepts Apple's updated agreement.
- [x] Verify/register identifier; create macOS app record; record app-specific URLs here.
- [x] Xcode target, explicit resources/icon, narrow sandbox, privacy manifest, inside-out library signing.
- [x] Imported audio security scope + read-only bookmark; reopened saved project after restart in actual sandbox.
- [x] Actual sandbox favorites, open/save panels and audio-inclusive native MP4 export.
- [x] Local team-signed sandbox ProjectM/Studio phone 4K60 export, existing-output replacement, bookmark restart, and compact/presentation layout checks.
- [x] Distribution app/library signatures, installer signature and provisioning profile validation.
- [ ] Repeated transition visibility and second-machine validation (see VALIDATION.md).
- [ ] Resolve preset/texture redistribution provenance and LGPL distribution terms (see LICENSES.md).
- [x] Confirm domain/public email.
- [x] Publish and verify reviewed support/privacy pages and App Privacy responses.
- [ ] Publish and verify the matching source package after third-party rights resolution.
- [ ] Complete listing, rights, age rating, privacy, pricing and availability.
- [x] Upload distribution artifact to Apple.
- [x] Apple processing completed; build assigned to internal Mac beta group.
- [x] Attach processed build 1.0.0 (2) to the App Store version.
- [ ] TestFlight or second Apple silicon Mac validation; macOS 14 machine if available.
- [ ] Final user approval to submit for review; manual release selected.

## Guided Apple setup and remaining distribution steps

1. At https://developer.apple.com/account/resources/identifiers/list choose team Protomota LLC. Search for `com.protomota.pulsecanvas`. If present, inspect its type/ownership. If absent, click **+**, choose **App IDs**, **App**, and Continue. Description: `PulseCanvas Studio`; Bundle ID: **Explicit**, `com.protomota.pulsecanvas`. Leave optional capabilities off. Review and Register. Do not register a different ID without checking the release configuration.
2. At https://appstoreconnect.apple.com/apps click **+ → New App**. Platform: **macOS**; Name: `PulseCanvas Studio`; Primary Language: `English (U.S.)`; Bundle ID: the verified identifier; SKU: `pulsecanvas-studio-macos`; User Access: `Full Access` for this organization. Click Create after inspecting the values. This record has already been created; do not create a duplicate.
3. Open the new record and record its exact app URL here. In **App Information**, set subtitle/categories from METADATA.md. In **App Privacy**, answer the audited data questions from PRIVACY.md and supply the published privacy-policy URL.
4. In **Pricing and Availability**, choose price **Free**. Territory availability is a user choice; prepare all territories unless instructed otherwise. Do not enable in-app purchases or subscriptions.
5. Open `PulseCanvas.xcodeproj` in Xcode. Select the app target, **Signing & Capabilities**, team **Protomota LLC**, identifier `com.protomota.pulsecanvas`, automatic signing. Stop and obtain action-time confirmation before creating new credentials or granting broader account access. Existing certificates/profiles may suffice.
6. Choose scheme **PulseCanvas**, destination **Any Mac (Apple silicon)**, **Product → Archive**. In **Window → Organizer → Archives**, select the archive. **Distribute App → App Store Connect → Upload**. Inspect team, identifier, version/build and signing details; validate and upload for private testing. Clear the documented publication, rights and runtime holds before final App Review submission. No private key should be pasted into chat.
7. At https://appstoreconnect.apple.com/apps open the new record, then **TestFlight**. Wait until processing succeeds; complete the encryption question if asked. Add an internal tester/group using the user's chosen recipients. External beta testing may require Beta App Review. Do not send invitations without authorization.
8. In the **macOS 1.0.0** version, attach the processed build, screenshots, metadata and review notes. Under **App Store Version Release**, select **Manually release this version**. Present the complete packet to the user before **Add for Review / Submit to App Review**. Release only after approval and explicit final authorization.

## Apple specifications checked

Screenshots: 1–10, opaque PNG/JPEG, macOS 16:10: 1280×800, 1440×900, 2560×1600 or 2880×1800. Real-app captures are prepared independently of the user's session. Optional preview is not required. Existing 44-second marketing and 2:37 walkthrough videos are not submission previews; the marketing launch claim must remain unpublished until live.

- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications
- https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/
- https://developer.apple.com/app-store/review/guidelines/

Local preparation includes four upload-size real-app screenshots in `assets/app-store/screenshots/` and a smaller Library reference in `work/app-store/`. Full-window Library/settings captures remain pending. Compact/presentation layout checks passed for all five aspect ratios. Source/rights inventory is in `build/app-store/`; private project bookmarks and session backups stay in ignored `work/` and `.build/`.

Engineering commit: `0b71e14`. Local sandbox test artifact: `build/app-store/PulseCanvas Sandbox Test.app` (Apple Development, separate validation identifier). Distribution package: `build/app-store/export/PulseCanvas Studio.pkg`; expanded app verified at `work/app-store/distribution-expanded/com.protomota.pulsecanvas.pkg/Payload/PulseCanvas Studio.app`. Source snapshot: `build/app-store/PulseCanvas-1.0.0-source.tar.gz`; source checksum file: `build/app-store/source-SHA256.txt`; asset inventory: `build/app-store/asset-rights-inventory.csv`.

## Mac TestFlight

### Build 1.0.0 (3), 2026-10-11

Changed the primary action to **Save video**. It opens the native save panel before rendering, allowing a destination folder, filename and new folders. The completed MP4 is saved there automatically. Removed both Play video actions; the success toast now says **Video saved** and offers only **Show in Finder**, with the same Finder action available afterward in the inspector. Updated in-app help and release documentation.

Source commit: `c9e37422d46dba340cfd612db0031f2583d2ef8f`, pushed to `codex/mac-app-store-preparation`. The isolated sandbox app was tested through the actual save panel with a one-second stereo soundtrack: it saved a 2160×3840, 60 fps H.264/AAC MP4 in the selected folder, showed the saved confirmation without a Play video action, and revealed the selected file in Finder. Full MP4 decoding passed. Archive, app/library signature, distribution profile and installer signature checks passed.

Artifacts: `build/app-store/PulseCanvas-1.0.0-3.xcarchive`, `build/app-store/export-1.0.0-3/PulseCanvas Studio.pkg`. Validation and upload logs: `work/save-video-update/`. Beta testing should cover choosing another destination, cancelling the save panel, saving a new MP4, replacing an existing output, and Show in Finder.

Apple accepted the upload at 17:05 EDT. Processing completed, build 3 shows Ready to Submit, and it is assigned to **PulseCanvas Mac Beta** (Internal, one existing tester). What to Test instructions are saved. The existing missing ProjectM dSYM warning remains and affects that library's crash symbolication. No public App Review submission or new tester access.

- Build 3: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/macos/fc45d2a4-0cea-499a-b907-be33bf639506

### Build 1.0.0 (2), 2026-10-11

Updated the bundled soundtrack from the user's replacement `PulseCanvas.wav`: 174.08 seconds, 48 kHz stereo, encoded as a 320 kbps MP3. Existing projects retain their soundtrack references; projects using the bundled PulseCanvas identifier resolve to the updated resource. Added vertical clearance to the Studio card scroll view so top/bottom borders remain visible, including when macOS reserves horizontal-scroller space.

Source commit: `ccdf8806a3c0a51a4a34e731169a9b975f32b338`, pushed to `codex/mac-app-store-preparation`. Bundled audio SHA-256: `8c863f65e8db705ab4003a2af6df15cf336bdbf92277ee981b5922b107dce8f7`.

Audio smoke checks passed, including default loading/PCM analysis, section loops, card selection and randomization replay, presentation, and end-of-track behavior. The isolated sandbox test app loads the new 2:54 soundtrack; live Studio inspection shows complete card borders. Signed archive, strict app/library signature, distribution profile and installer signature checks passed. The expanded distribution package contains the exact new MP3. Apple accepted the upload at 12:13 EDT. The existing missing ProjectM dSYM warning remains; it affects that library's crash symbolication, not upload acceptance.

Artifacts: `build/app-store/PulseCanvas-1.0.0-2.xcarchive`, `build/app-store/export-1.0.0-2/PulseCanvas Studio.pkg`. Validation and upload logs: `work/soundtrack-update/`. What to Test: check the new default soundtrack plays and loops, native/ProjectM previews react to it, Studio card borders remain visible while scrolling, and audio-inclusive MP4 export succeeds.

Apple processing completed; build 2 shows Ready to Submit and is assigned to **PulseCanvas Mac Beta** (Internal, one existing tester). What to Test instructions are saved. This does not establish a completed tester installation or public App Store approval.

- Build 2: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/macos/e7486a75-10f5-47da-96d6-ca5496a513c0

Installed Apple’s TestFlight app on this Mac from the Mac App Store on 2026-10-11. Internal group **PulseCanvas Mac Beta** contains only Brad Dunlap’s existing Account Holder account; automatic build distribution is off. Beta description and `support@pulsecanvas.si` feedback email are saved. The earlier invited/pending state has been superseded: native TestFlight inspection now shows PulseCanvas Studio **1.0.0 (2)** with an **Open** button, confirming installation on this Mac. Evidence: `work/app-store/testflight-build2-installed.jpg`. Full end-to-end checks in that installed copy and second-machine validation remain pending. No external tester invitation or Beta App Review submission.

- Beta group: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/groups/e06555d7-c301-4fd1-9ab3-572521a25ba6
- TestFlight download: https://apps.apple.com/us/app/testflight/id899247664
- Apple’s Mac installation instructions: https://testflight.apple.com/

Accept Apple’s email invitation on the Mac using **View in TestFlight → Accept → Install**, or open the existing PulseCanvas entry in TestFlight and update it. Verify version 1.0.0 (3), launch, import audio, save/reopen after restart, and save native and ProjectM Studio videos. An accepted upload establishes successful transport/initial Apple validation, not completed processing, a successful beta install, or App Review approval.

## Latest internal beta — 1.0.1 (4)

Apple processing is complete for **1.0.1 (4)**; assigned to the existing **PulseCanvas Mac Beta** internal group (1 tester). The unused-code audit, checks, source snapshot and delivery evidence are recorded in [TESTFLIGHT-1.0.1-4.md](TESTFLIGHT-1.0.1-4.md). This supersedes the earlier beta build numbers, while the public submission gates remain unchanged.

## Current review submission and internal beta — 1.0.1 (7)

Build 7 was uploaded, processed and assigned to the existing **PulseCanvas Mac Beta** internal group (one tester) on 2026-10-12. The old 1.0.0 (3) review submission was canceled with the owner’s authorization, the public version changed to 1.0.1, and build 7 submitted. Apple shows **Waiting for Review**. Seven screenshots, description, URLs, contacts and **manual release** remain intact. Reviewer/testing notes describe the destination-first video save flow, second-export support prompt and storefront tip-link eligibility. Build 7 also includes the updated first-party noncommercial source license while allowing official-app commercial video production and preserving third-party rights. Builds 5 and 6 were prepared but never uploaded. See [TESTFLIGHT-1.0.1-7.md](TESTFLIGHT-1.0.1-7.md) for the signed candidate, source snapshot and delivery receipt. This supersedes older status/build statements above; review approval and public release remain pending.

## Ratings priority update — 1.0.1 (8)

Build 8 supersedes build 7. It prioritizes the automatic StoreKit rating request directly after the second successful export and puts App Store rating first in the styled, user-initiated ratings/support screen, optional tipping second, then sharing and feedback. The App Store build no longer automatically opens a custom support prompt before the rating request. Signed artifact and milestone validation passed; Apple processed the build and it is assigned to the existing internal beta group. See [TESTFLIGHT-1.0.1-8.md](TESTFLIGHT-1.0.1-8.md) for the verified review receipt. Manual release is retained.
