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
