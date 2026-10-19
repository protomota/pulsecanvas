# Vision Pro 1.1.5 (12) — App Store review submission

**Historical receipt:** this submission was later voluntarily canceled to replace
the outdated Radio video and screenshots. See the [Radio media refresh receipt](vision-1.1.5-radio-media-refresh.md) for the replacement assets and current status.

Submitted October 19, 2026 at **3:34 PM EDT**. Apple reports
`WAITING_FOR_REVIEW` for the version and its submission.

- [Submission detail](https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/9f64771e-c704-43fd-8f8d-32a6be418d61)
- Submission: `9f64771e-c704-43fd-8f8d-32a6be418d61`
- Selected build: 1.1.5 (12), `1f51a7aa-9dfb-44f7-a4fd-f220dfc9404a`
- Binary/source/signature evidence: [TestFlight delivery receipt](vision-1.1.5-12.md).

## Listing and media

The saved English description covers hundreds of native Metal effects, music
response, Studio scene timing, favorites/categories, Radio song favorites,
immersive viewing, project interchange and MP4 exports up to 4K/60fps. Completely
free/no subscriptions/no paid features and the correct GitHub source URL appear
near the bottom. It makes no open-source-license or external-engine claim.
Promotion, keywords, URLs, copyright and platform-specific reviewer instructions
were updated. Exact copy is in [the committed metadata](../app-store/vision-1.1.5.en-US.json).

The shared subtitle previously said “made on your Mac”. It now reads “Music
visuals, made by you”, verified by API. High motion is declared for Vision Pro.
Pricing is zero; the existing privacy-policy URL and Data Not Collected
declaration were verified. Existing age ratings and content-rights declarations
were retained. Apple's validation initially required the missing shared Apple TV
plain-text privacy policy even for this Vision submission. Its text now reflects
the existing local-data and Radio-network practices and links to the policy and
support pages. The exact saved text is [committed separately](../app-store/apple-tv-privacy-policy.txt).

Six native 3840×2160 RGB PNGs were uploaded in order: immersion, Studio,
visualizer picker, export, Radio favorite songs and Radio playback. Five were
freshly captured from the current native simulator interface; the unchanged
full-immersion hero was retained. They contain no macOS/Creators Edition UI.

The three approved 4K30 previews were uploaded unchanged: Immersion v2, Studio
v3 and Radio v2. There was no recut or new narration. All three reached Apple
`assetDeliveryState=COMPLETE` and `videoDeliveryState=COMPLETE` with no reported
errors/warnings. The six screenshots reached `COMPLETE` with 3840×2160 image
assets. All nine source checksums match the actual local files. Filenames and
SHA-256 hashes are in [the asset manifest](../app-store/vision-1.1.5-assets.json).
Successful processing is not a claim of App Review approval.

## Verification and scope

- Fresh API reads confirm the exact saved description, promotion, keywords,
  support/marketing URLs, reviewer notes, privacy text and subtitle, plus the
  selected build and `WAITING_FOR_REVIEW` submission/version states.
- The visible App Store Connect confirmation showed “1 Item Submitted”. The
  final detail page shows visionOS 1.1.5 (12), Waiting for Review and the exact
  submission ID/time.
- Both native capture tests passed: 2 tests, 0 failures, 454.432 seconds,
  including Radio favorites, full immersion and Studio/picker/export flows.
  Xcode stalled after reporting the successful suites and was interrupted during
  cleanup; no normal exit-0 test-command claim is made. The earlier build-12
  functional layout tests completed normally as recorded in its receipt.
- A test-only opt-in `PULSECANVAS_CAPTURE_STILL_HOLD` pauses at capture marks so
  Device Hub can save native 4K screenshots. No application/binary code changed.
- Support, privacy, homepage and GitHub URLs returned HTTP 200. A separate
  command-line probe of the Radio index returned HTTP 403; the native Radio
  capture test loaded and played music successfully. No general network or
  physical-device availability claim is inferred from those checks.
- Physical headset installation, comfort, gaze/hand targets and sustained
  performance were not tested in this submission task. The capture flow opens
  export settings; the real Files-save test is documented in the earlier media
  preparation receipt and was not repeated here.
- Mac 1.1.4 remains Waiting for Review in the same existing submission
  `30d1010c-4d74-4d36-8aea-96099ca56c43`; it was not withdrawn or replaced. TV 1.0
  remains a draft. Shared subtitle/privacy metadata changed as described above.
- Existing automatic release after approval was retained. No website deployment,
  external beta review or public media publication was performed.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/Vision Pro/1.1.5/`

Screenshots, manifests, saved copy, checksums, exact API readbacks, native test log
and `source/submitted-confirmation.png` / `source/review-submission-detail.png`
remain local. Private review-contact audits and binaries are excluded from Git.
The approved preview masters remain in the sibling `1.0/previews/` directory.
