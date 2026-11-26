## Apple submission withdrawn at owner request — 2026-10-14

App Store 1.1.0 (15) was withdrawn after the owner clarified they were not ready to submit. Apple confirms submission `ffaffc6b-8c07-40c3-b645-4ed8d7000c1b` is **Removed** and version 1.1.0 is **Developer Rejected**. The uploaded build and listing remain available for later preparation. Do not resubmit without explicit owner approval. The website release is unchanged.

The submission status in earlier dated entries below is historical.

## Version 1.1.0 (15) released to website and submitted to Apple — 2026-10-14

Creators 1.1.0 (15) is live at https://pulsecanvas.si/download/. App Store 1.1.0 (15) is **Waiting for Review**, with automatic release after approval. Apple submission: https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/ffaffc6b-8c07-40c3-b645-4ed8d7000c1b . This is not an App Review approval claim.

Includes Radio with a public JSON station directory, all 15 tracks, favorites-first visualizer shuffle, beat-aligned bars, current-visual randomization, full-screen presentation, remembered volume defaulting to 70%, close-to-quit behavior, safe title-bar controls, and unique Studio timeline shuffles. Both editions contain 270 native effects; Creators also contains 7,758 community presets and 67 textures. Radio catalogs and songs are downloaded from https://radio.pulsecanvas.si; user files are not uploaded. The published privacy policy explains these requests.

Store archive/expanded installer signatures, native-only resources and sandbox/network entitlements passed. Creators signing, Accepted notarization, stapling, Gatekeeper and pinned Sparkle signature passed. Radio's 15 live tracks and the 270-visual Store suite passed. All 8,145 source files and all 95 deployed website file hashes were verified. Matching source, new installer and signed appcast are published; old releases remain available. Unrelated unpublished website edits were excluded. No Git commit or push was made.

- Installer: https://pulsecanvas.si/downloads/PulseCanvas-Studio-1.1.0-15.dmg
- Matching source: https://pulsecanvas.si/downloads/PulseCanvas-Creators-1.1.0-15-source.tar.gz
- Update feed: https://pulsecanvas.si/appcast.xml
- Local receipt: `.build/release-1.1.0-15/release-receipt.json`

Older dated status entries below are historical.

# Native marketing screenshot update — 2026-10-13

The live macOS version **1.0.3 (13)** now shows **Waiting for Review**. The listing now contains three native marketing slides followed by four actual native Metal edition screenshots; its screenshot uploader is disabled again after resubmission. Older audit entries below are historical and do not describe the current edition or review status.

Three new 1440 × 900 opaque RGB marketing slides were created in `assets/app-store/native-marketing-1.0.3-13/`, using unchanged source captures from the actual STORE_BUILD app with 240 native Metal visualizers. The slides cover music response, beat-aligned Studio scenes and MP4 export up to 4K60. No Creators screenshots, community preset counts or OpenGL visuals are used. Source hashes, JPEG dimensions/components, full capture bounds and browser image loading were verified; the actual final Store app bundle remains version 1.0.3 (13) and contains no .milk presets, projectM or Sparkle resources.

All three slides were uploaded to **Apple Asset Library** and processed successfully as App Screenshots. Their persisted filenames, asset detail links and Add for Review state were verified after reloading. Receipt: `assets/app-store/native-marketing-1.0.3-13/manifest.json`; visual proof: `app-store-asset-library.jpg` in the same folder.

**Listing replacement and resubmission completed with owner approval.** The prior submission was withdrawn; all seven assets were selected from the retained Asset Library in order and saved. Their persisted order was verified after reloading: `01-music-in-motion.jpg`, `02-build-your-studio.jpg`, `03-create-and-export.jpg`, `01-led-corridor.jpg`, `02-molten-glass.jpg`, `03-studio.jpg`, `05-aurora-fold.jpg`. The existing description, promotional text, review notes and release setting were preserved.

The same **1.0.3 (13)** build, ID `314e2cee-23d7-4bd1-b057-fef9c842381a`, was verified before and after resubmission. Apple confirmed **1 Item Submitted** and **Waiting for Review**. New submission: https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/5944228d-078f-4759-8545-91a187802b05 . Proof: `app-store-listing-submitted.jpg` and `app-store-submission-confirmed.jpg` in the native marketing asset folder. No new binary was uploaded, no Git commit or push was made, and App Review approval has not been claimed.

Live asset library: https://appstoreconnect.apple.com/apps/6821642700/distribution/asset-library
Live version: https://appstoreconnect.apple.com/apps/6821642700/distribution/macos/version/inflight

---

# Live submission audit — 2026-10-11

PulseCanvas Studio, Apple ID 6821642700, macOS version 1.0.0, English (U.S.). **Preparation remains in progress; no final App Review submission or release.**

## Saved and verified in Apple

- Build **1.0.0 (2)** attached to the App Store version, with the app icon included.
- Name, 30-character subtitle, Photo & Video / Music categories, 1,018-character description, 85-character keywords, copyright, review contact and 668-character review notes.
- Promotional text, 162/170 characters.
- Marketing URL https://pulsecanvas.si/ and Support URL https://pulsecanvas.si/support/.
- Privacy policy URL https://pulsecanvas.si/privacy/; audited **Data Not Collected** responses published. Owner authorization received and Apple's published status verified on 2026-10-11. Evidence: `work/app-store/privacy-published.jpg`.
- Age questionnaire saved: Apple calculated **13+**, with regional variations and a 12+ global rating on operating systems before version 26. Infrequent mature references are in original preset names/tooltips. All 67 decoded bundled texture images and a local transcription of the current demo song were reviewed.
- Free price ($0.00); 175 available territories; public App Store distribution; manual release; no sign-in or Game Center.
- Current app-level DSA declaration shows non-trader. This audit did not make a new legal classification. Organization status alone and free pricing do not settle the self-assessment; the Account Holder remains responsible for that existing declaration.
- Optional accessibility labels, preview video, sandbox explanation attachment, and IAP/subscription/server-notification fields are not invented or filled with unsupported claims.

## Screenshot correction

The four original files named `.png` actually contained JPEG data. Apple showed red processing-error placeholders. Filenames were corrected to `.jpg` without changing the image bytes. The failed screenshot records and retries were removed **from this version only**; Apple's dialog expressly says they remain in the Asset Library. No unrelated app/build cleanup took place.

Original screenshot order before marketing cards: `01-prism-wake.jpg`, `02-spiral-tide.jpg`, `04-studio.jpg`, `05-export.jpg`. All are opaque RGB, 1440×900. All four processed thumbnails were verified in Apple's media manager: each has a rendered image, no error and no pending indicator. Visual evidence: `work/app-store/listing-screenshots-ready.jpg`.

## Opening feature cards uploaded — 2026-10-11

Owner authorized App Store publication of three adapted feature cards using HTML/CSS with unchanged real app captures. Apple's guideline 2.3.3 requires screenshots to show the app in use and allows text/image overlays. The artwork-only campaign masters remain local; the listing versions include large real app captures and decorative campaign artwork.

Exports in `assets/app-store/feature-cards/` were checked as opaque RGB JPEG, 1440×900. Seven processed thumbnails and the final order were verified after reloading App Store Connect. Current order: `01-your-visual-world.jpg`, `02-signature-look.jpg`, `03-beat-to-video.jpg`, then `01-prism-wake.jpg`, `02-spiral-tide.jpg`, `04-studio.jpg`, `05-export.jpg`. The four existing screenshots remain unchanged. Evidence: `work/app-store/feature-cards-uploaded.jpg`.

These assets are saved in the unreleased macOS 1.0.0 listing; they are not publicly visible on the App Store yet. No App Review submission, public release or website publication was performed.

## Support update published

- Preview: https://pulsecanvas-website-7v4f0cqhd-protomota.vercel.app/support/
- Deployment: `dpl_B77Aa2MSoGoJZeXNh4ckYk9yofQX`; successful Vite/prebuilt preview deploy, verified in personal Chrome.
- Changes: replace the private GitHub bug-report action with `mailto:support@pulsecanvas.si`; request app/macOS versions and reproduction steps; preserve that personal support and a response/fix are not guaranteed. No repository visibility change.
- Owner approved production publication. The Vercel connector's direct promotion returned HTTP 422; the official CLI promotion created the READY production deployment `dpl_A7zsBUAinnYz9uaAYNBrMiTdoJ1B`. Its aliases include pulsecanvas.si and www.pulsecanvas.si. Live https://pulsecanvas.si/support/ was verified in personal Chrome with the email action and reproduction guidance.
- Visual evidence: `work/app-store/support-production.jpg`.

## Matching source prepared locally

`build/app-store/PulseCanvas-1.0.0-2-source.tar.gz` was refreshed from revision `a8f7e93f481b7f99a21305789af47d32e70cc6f7` (same application code as build 2 plus listing documentation/assets). The packaged soundtrack matches the distribution build's SHA-256. Archive inspection found no signing key/profile extensions. The previous source archive/checksum were preserved separately as build 1 evidence. Build 2 checksum: `build/app-store/source-1.0.0-2-SHA256.txt`. This archive remains local pending the rights/source publication decision; packaging does not establish third-party permissions.

## Remaining gates

1. **Public corresponding source.** Support and privacy publication are complete. The matching archive, checksum, inventory and standalone `/source/` page are staged locally at `build/app-store/source-publication/`. Public source distribution remains pending the particular third-party rights questions; see RIGHTS-RESOLUTION.md. No whole-repository visibility change is authorized or performed.
2. **Third-party content rights.** Apple's Content Rights choices require either no third-party content or third-party content with all necessary rights. The app contains third-party presets/textures. New curator inclusion/attribution evidence is recorded, and the three focused preset/texture/vendor requests have been posted with explicit owner authorization; responses remain pending. This is not proof of every author's grant. The declaration remains unset. Brad's own shaders and commercial-use Suno song/narration attestations remain accepted. Exact links are in RIGHTS-RESOLUTION.md.
3. **Beta validation and final owner approval.** TestFlight on this Mac now shows version **1.0.0 (2)** with an **Open** button, confirming installation. Evidence: `work/app-store/testflight-build2-installed.jpg`. A completed end-to-end test of that installed copy and second-machine test have not been established. Existing engineering evidence is in VALIDATION.md. Do not click Add for Review / Submit to App Review or release before the final review packet is approved.

Owner chose to **keep all effects and prepare the rights/source resolution**. Preserve the full application and counts. The native-only alternative is not selected. Exact outbound drafts and source-publication preparation are in RIGHTS-RESOLUTION.md.

## Exact Apple destinations

- Version: https://appstoreconnect.apple.com/apps/6821642700/distribution/macos/version/inflight
- Screenshots: https://appstoreconnect.apple.com/apps/6821642700/distribution/macos/version/inflight/media-manager
- App information, age and rights: https://appstoreconnect.apple.com/apps/6821642700/distribution/info
- Published privacy responses: https://appstoreconnect.apple.com/apps/6821642700/distribution/privacy
- Pricing: https://appstoreconnect.apple.com/apps/6821642700/distribution/pricing
- Latest beta build: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/macos/e7486a75-10f5-47da-96d6-ca5496a513c0

After the gates are cleared and the owner approves submission: open the Version URL above, confirm build **1.0.0 (2)** (or the replacement explicitly prepared for a changed edition), click **Add for Review**, inspect the resulting submission, then **Submit to App Review**. After approval, manual release remains a separate owner-authorized action.

## References checked

- Apple's Standard EULA preserves rights allowed by included open-source licenses; a custom EULA is not automatically required solely because ProjectM is LGPL: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Privacy publishing: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- Accessibility labels are currently voluntary; claims require evaluation: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels
- DSA self-assessment and verification: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/
- Preset pack's actual upstream notice: https://github.com/projectM-visualizer/presets-cream-of-the-crop/blob/master/LICENSE.md
