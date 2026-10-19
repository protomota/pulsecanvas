# Vision Pro 1.0 — submission preparation

October 19, 2026. The latest internal TestFlight build is [1.0 (8)](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/e7c7d3ea-30b1-4147-9748-1a367f62107c), including Radio song favorites. See [delivery receipt](../releases/vision-1.0-8.md).

The Vision-specific 1.0 listing remains a draft. Its audit found an empty English description and no selected build. No public review submission, website deployment or public media upload was performed during this preparation. Mac 1.1.4 remains Waiting for Review.

## Prepared assets

`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/Vision Pro/1.0/`

- Six 3840×2160 RGB native simulator screenshots: immersion, Studio, visualizer picker, export settings, Radio song favorites, Radio playback.
- A screenshot manifest records actual dimensions, alpha absence and SHA-256 hashes.
- `source/metadata-draft.json` contains the English description, promotion, keywords, URLs and reviewer instructions, including song favorites. It uses “hundreds” rather than exact effect counts, “completely free”, and “source available on GitHub” with the PulseCanvas repository. It does not claim an open-source license.
- Private review-contact audit files remain local; do not publish the entire directory.

## Three App Store preview drafts

Source projects live in `/Volumes/Music/Video/astra_video/videos/pulsecanvas-vision-appstore/`:

- [Immersion](http://localhost:3031/#project/01-immersion): 17 seconds entirely in native full immersion, with the room, Studio window and floating controls hidden.
- [Studio](http://localhost:3032/#project/02-studio): 24 seconds showing the visualizer picker/export settings, followed by 12 seconds of actual full immersion.
- [Radio](http://localhost:3033/#project/03-radio): 24 seconds showing song hearts and the favorites browser, followed by 14 seconds of actual Radio full immersion.

All use actual native simulator footage, the existing selected Emma narration (voice ID `9HBoEQ8LqyvVZFYDodnr`) and music from the displayed songs. A shared narration bus drives spectral carving and ducking. The short corner title and closing label leave the app visible throughout. Originals are preserved. A fresh 3840×2160 simulator recording supplies the immersive sequences; these are not enlarged editor previews. Two opt-in capture tests verified the floating controls were hidden before marking usable footage. Both suites passed with zero failures; the Xcode runner was stopped after post-suite cleanup stalled. No runtime app code or release version changed for this media revision.

HyperFrames pins were updated from 0.8.157 to 0.8.174. All three final checks pass with zero lint, runtime, layout, motion or contrast findings. Frames at 2, 9 and 15 seconds and the live Radio preview were inspected. Animation maps were reviewed: native video supplies motion during intervals without authored opacity tweens. Checks and hashed media ledgers remain in the projects.

Final MP4 renders await the owner's preview approval, as required by the video workflow. No final-file codec, frame-rate, decode or audio-loudness validation is claimed yet.

## Remaining before submission

1. Approve the previews, render at 3840×2160/30fps, and verify decoded output, narration/music levels, no unintended black frames, duration and file size.
2. Apply verified copy to the Vision-specific listing, select build 1.0 (8), and upload approved screenshots/previews. Do not change the Mac review submission.
3. Verify required motion information, privacy and age-rating declarations and reviewer fields against the actual app. Check export/save, targets, immersion comfort and sustained performance on a physical headset; simulator checks do not establish those results.
4. Submit only when authorized. Keep the separate website draft and marketing films unpublished until the owner confirms the app is live and supplies the Vision Pro App Store URL.

Apple references: [preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications), [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [visionOS submission guidance](https://developer.apple.com/visionos/submit/).
