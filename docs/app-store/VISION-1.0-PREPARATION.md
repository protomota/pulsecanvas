# Vision Pro 1.0 — submission preparation

October 19, 2026. The latest internal TestFlight build is [1.0 (8)](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/e7c7d3ea-30b1-4147-9748-1a367f62107c), including Radio song favorites. See [delivery receipt](../releases/vision-1.0-8.md).

The Vision-specific 1.0 listing remains a draft. Its audit found an empty English description and no selected build. No public review submission, website deployment or public media upload was performed during this preparation. Mac 1.1.4 remains Waiting for Review.

## Prepared assets

`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/Vision Pro/1.0/`

- Six 3840×2160 RGB native simulator screenshots: immersion, Studio, visualizer picker, export settings, Radio song favorites, Radio playback.
- A screenshot manifest records actual dimensions, alpha absence and SHA-256 hashes.
- `source/metadata-draft.json` contains the English description, promotion, keywords, URLs and reviewer instructions, including song favorites. It uses “hundreds” rather than exact effect counts, “completely free”, and “source available on GitHub” with the PulseCanvas repository. It does not claim an open-source license.
- Private review-contact audit files remain local; do not publish the entire directory.

## Three App Store previews — revised cut awaiting render approval

Source projects live in `/Volumes/Music/Video/astra_video/videos/pulsecanvas-vision-appstore/`:

- [Immersion](http://localhost:3031/#project/01-immersion): revised 21.6-second montage with 12 different native effects, including coaster tunnels, fractals, woven passages and light effects. The room, Studio window and floating controls are hidden.
- [Studio](http://localhost:3032/#project/02-studio): revised 22.8 seconds showing the picker/export settings, followed by six different immersive effects in 10.8 seconds.
- [Radio](http://localhost:3033/#project/03-radio): revised 24 seconds showing the Electronic station playing “Neon Tidewater”, song favorites, and 14 seconds of distinct native full immersion. The prior bluegrass song is absent from this revision.

All use actual native simulator footage, the existing selected Emma narration (voice ID `9HBoEQ8LqyvVZFYDodnr`) and music from the displayed songs. A shared narration bus drives spectral carving and ducking. The short corner title and closing label leave the app visible throughout. Originals are preserved. A fresh 3840×2160 simulator recording supplies the immersive sequences; these are not enlarged editor previews. Two opt-in capture tests verified the floating controls were hidden before marking usable footage. Both suites passed with zero failures; the Xcode runner was stopped after post-suite cleanup stalled. The release version is unchanged; the separate immersive-toolbar update is described below.

HyperFrames pins were updated from 0.8.157 to 0.8.174. All three final checks pass with zero lint, runtime, layout, motion or contrast findings. Frames at 2, 9 and 15 seconds and the live Radio preview were inspected. Animation maps were reviewed: native video supplies motion during intervals without authored opacity tweens. Checks and hashed media ledgers remain in the projects.

The earlier approved 3840×2160/30fps H.264/AAC exports remain preserved in the asset package’s `previews/` folder. The table below describes those earlier files, not the revised cut:

| Film | Duration | Frames | Size (decimal MB) | Integrated loudness | True peak |
| --- | --- | --- | --- | --- | --- |
| Immersion | 17 s | 510 | 79.9 | -19.4 LUFS | -2.7 dBFS |
| Studio | 24 s | 720 | 78.1 | -20.1 LUFS | -2.7 dBFS |
| Radio and favorites | 24 s | 720 | 107.2 | -20.5 LUFS | -2.7 dBFS |

All three fully decoded with no errors. Probes confirm constant 30fps, 3840×2160, yuv420p, BT.709 and stereo AAC at 48kHz. No black frames were detected. Decoded frames, including both sides of scene cuts, were inspected: immersive ranges fill the frame with the room/window/controls hidden. Studio’s two freeze-detector findings are its static picker/export settings, outside immersion. Logs, frame samples, hashes and complete probes are in `previews/qc/verification.json`. These are measurement and frame-review results, not a subjective audio listening or exact music-waveform-sync claim.

The initial strict export failed safely on duplicate music automation: a legacy volume attribute hid the valid versioned carve lanes. The old fade points were merged into the version-1 envelope, retaining the spectral carve and ducking. All three checks then passed, and all three strict delivery renders completed using hardware GPU `drawelement` capture.

No upload acceptance is claimed. Apple lists 3840×2160 for Vision Pro previews, while its generic encoding table specifies H.264 up to High 4.0, 10–12Mbps and AAC 256kbps. These quality masters use the valid 4K H.264 High 5.1 profile at approximately 26–37Mbps and AAC 192kbps. Confirm or conform submission encoding against App Store Connect before upload; do not relabel 4K video as Level 4.0. The approved edit and original masters remain preserved.


## Variety revision and immersive toolbar

The revised compositions are built and validated, but have not been approved or rendered as new final MP4s. All three checks passed after preparing smaller 4K30 source clips. Snapshots covered every shot in the 12-effect montage and the Studio/Radio scenes. The first and Studio immersive selections use disjoint native scene IDs, and Radio’s full-immersion range uses another distinct sequence. Blue, green, gold, purple and mixed palettes were inspected; this is not a single-purple presentation. Footage remains the real simulator output with no grading or fabricated camera movement. Capture settings use the actual Studio paths: one-bar scenes, Chaos 0.85, zoom speed 2, motion speed 1.3, strobe off. The included instrumental bed and existing selected narration remain in the first two previews. Radio’s new bed comes from the same “Neon Tidewater” track visible in the recording; alignment is estimated from transport/capture marks, not claimed waveform-perfect.

`source/variety-revision/` holds the native 3840×2160 recording, original timestamps, real scene grids, isolated project snapshots, Radio track provenance and capture-test logs. Both opt-in capture tests passed with zero failures (127.6 seconds); their runner was stopped after post-suite cleanup stalled. These debug captures require `SWIFT_ACTIVE_COMPILATION_CONDITIONS="STORE_BUILD DEBUG"` and `-PCUITesting`; ordinary launches and release builds do not apply the capture sequence. The user's own projects and soundtrack were not used.

The immersive toolbar is now one centered horizontal row. Vertical separators group song controls, visualizer controls and viewing controls. The hearts explicitly say “Save song” and “Save visualizer”, changing to “Song saved” and “Visualizer saved”. Song titles and visualizer names stay on one line; edge smoothing moved into Viewing settings. The final UI test passed with normal test-command exit 0, verifying independent favorite actions, unchanged state of the other heart, button-center alignment within 3 points and paused controls remaining visible beyond the auto-hide interval. Simulator screenshots are in `source/variety-revision/immersive-controls-saved-and-aligned.png` and its detail crop. This toolbar update is built locally and on main; no new TestFlight build or App Store submission was made.

## Remaining before submission

1. Approve and render the revised previews, verify the actual new output, then resolve final submission encoding/acceptance against Apple’s preview specifications. Earlier approved masters remain preserved.
2. Apply verified copy to the Vision-specific listing, select build 1.0 (8), and upload approved screenshots/previews. Do not change the Mac review submission.
3. Verify required motion information, privacy and age-rating declarations and reviewer fields against the actual app. Check export/save, targets, immersion comfort and sustained performance on a physical headset; simulator checks do not establish those results.
4. Submit only when authorized. Keep the separate website draft and marketing films unpublished until the owner confirms the app is live and supplies the Vision Pro App Store URL.

Apple references: [preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications), [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [visionOS submission guidance](https://developer.apple.com/visionos/submit/).
