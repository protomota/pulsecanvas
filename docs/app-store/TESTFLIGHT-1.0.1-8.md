# Ratings priority update — 1.0.1 (8)

Uploaded, processed and assigned to the existing PulseCanvas Mac Beta internal group (one tester) on 2026-10-12. Submitted for replacement review at 08:38 EDT; **Waiting for Review** verified. Source revision `284e3b9a98083b2162c364d1458972243abfbdef`. Signed archive/distribution validation and portable/Store-build engagement milestone tests passed.

The second successful export now makes the one-time StoreKit review request directly after the saved-video toast, once the app is active without another sheet. It no longer waits for the support window to close. The App Store build shows no automatic custom support/review pre-prompt; Apple decides whether to display its rating/review sheet, and TestFlight suppresses it. First, canceled and failed exports do not trigger it; relaunch, concurrent windows and earlier prompt history retain one-time suppression.

The user-initiated Help > Ratings, sharing & support screen has explicit ratings/reviews copy and a highlighted **Rate on the App Store** action first, **Optional developer tip** second, then sharing and feedback. The existing USA StoreKit storefront-only tip policy is preserved. Help also has a permanent App Store review deep link. No score requested, sentiment filter, rating incentive or feature restriction. All features remain free. The original styled support design was inspected using its actual SwiftUI views in an isolated preview app; no production app/session/preferences were replaced.

Apple requires its API for automatic review prompts: https://developer.apple.com/app-store/review/guidelines/#app-store-reviews . Its documentation describes a user-initiated `action=write-review` App Store link: https://developer.apple.com/documentation/storekit/requesting-app-store-reviews . This separates the automatic Apple sheet from the explicitly opened styled support screen.

Archive: `build/app-store/PulseCanvas-1.0.1-8.xcarchive`. Distribution: `build/app-store/export-1.0.1-8/PulseCanvas Studio.pkg`. Committed source snapshot: `build/app-store/PulseCanvas-1.0.1-8-source.tar.gz`. Logs: `work/rating-priority/`. Existing unrelated screenshot/marketing work is preserved.

The owner authorized updating/replacing the submission. Keep manual release, metadata, screenshots and the existing internal beta tester/group. No final public release is authorized.

Source archive SHA-256: `bb110817e22d4ab1c4a2a9abaae4481c6097a9adc63ee1513e7152c5c1a19031`. Apple accepted upload with the existing missing libprojectM dSYM warning. Build 7 submission `8892e688-1622-4011-8494-77011376a307` was canceled as authorized.

Build: https://appstoreconnect.apple.com/teams/69a6de6e-7488-47e3-e053-5b8c7c11a4d1/apps/6821642700/testflight/macos/686816f9-2ab8-42f6-83c9-aacbc296df75

Replacement submission: https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/fc05a326-a9bf-4313-80ea-66ff81f8464f

Verified macOS 1.0.1, binary 1.0.1 (8), Waiting for Review, submitted 2026-10-12 08:38 EDT. Seven screenshots, description, URLs, contacts and manual release retained. Screenshot evidence: `outputs/app-store-build8-submitted.png`; design: `outputs/ratings-first-support.png` in the task output directory. Approval and public release remain pending.
