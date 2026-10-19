# Vision Pro 1.0 — submission preparation

October 19, 2026. The latest internal TestFlight build is [1.0 (10)](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/8e4b1270-69fe-4761-b104-2e2dde88da8b), adding full-width Radio with bottom controls, fresh randomized looks and favorite-settings snapshots. It retains Ratings & Support and native review milestones. See [delivery receipt](../releases/radio-bottom-controls-2026-10-19.md).

The Vision-specific 1.0 listing remains a draft. Its audit found an empty English description and no selected build. No public review submission, website deployment or public media upload was performed during this preparation. Mac 1.1.4 remains Waiting for Review.

## Prepared assets

`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/Vision Pro/1.0/`

- Six 3840×2160 RGB native simulator screenshots: immersion, Studio, visualizer picker, export settings, Radio song favorites, Radio playback.
- A screenshot manifest records actual dimensions, alpha absence and SHA-256 hashes.
- `source/metadata-draft.json` contains the English description, promotion, keywords, URLs and reviewer instructions, including song favorites. It uses “hundreds” rather than exact effect counts, “completely free”, and “source available on GitHub” with the PulseCanvas repository. It does not claim an open-source license.
- Private review-contact audit files remain local; do not publish the entire directory.

## Three revised App Store preview masters

Source projects live in `/Volumes/Music/Video/astra_video/videos/pulsecanvas-vision-appstore/`:

- [Immersion](http://localhost:3031/#project/01-immersion): revised 21.6-second montage with 12 different native effects, including coaster tunnels, fractals, woven passages and light effects. The room, Studio window and floating controls are hidden.
- [Studio](http://localhost:3032/#project/02-studio): revised 25.2 seconds following timeline setup, timing/style controls, export settings, actual rendering, Files saving and the “Video saved” confirmation, followed by six different immersive effects in 9 seconds. Fresh narration describes each action on its corresponding screen; the unrelated “hundreds” line is removed.
- [Radio](http://localhost:3033/#project/03-radio): revised 24 seconds showing the Electronic station playing “Neon Tidewater”, song favorites, and 14 seconds of distinct native full immersion. The prior bluegrass song is absent from this revision.

All use actual native simulator footage, the existing selected Emma narration (voice ID `9HBoEQ8LqyvVZFYDodnr`) and music from the displayed songs. A shared narration bus drives spectral carving and ducking. The short corner title and closing label leave the app visible throughout. Originals are preserved. A fresh 3840×2160 simulator recording supplies the immersive sequences; these are not enlarged editor previews. Two opt-in capture tests verified the floating controls were hidden before marking usable footage. Both suites passed with zero failures; the Xcode runner was stopped after post-suite cleanup stalled. The release version is unchanged; the separate immersive-toolbar update is described below.

HyperFrames pins were updated from 0.8.157 to 0.8.174; the later Studio save recut alone advances to 0.8.175 and passes its strict check. All three final checks pass with zero lint, runtime, layout, motion or contrast findings. Frames at 2, 9 and 15 seconds and the live Radio preview were inspected. Animation maps were reviewed: native video supplies motion during intervals without authored opacity tweens. Checks and hashed media ledgers remain in the projects.

The latest 3840×2160/30fps H.264/AAC masters use `-v2.mp4` for Immersion and Radio and `-v3.mp4` for Studio in the asset package’s `previews/` folder. The earlier approved exports remain preserved. The table describes the actual revised files:

| Film | Duration | Frames | Size (decimal MB) | Integrated loudness | True peak |
| --- | --- | --- | --- | --- | --- |
| Immersion | 21.6 s | 648 | 160.1 | -19.9 LUFS | -2.8 dBFS |
| Studio | 25.2 s | 756 | 58.4 | -15.8 LUFS | -1.4 dBFS |
| Radio and favorites | 24 s | 720 | 113.0 | -20.4 LUFS | -2.7 dBFS |

All three fully decoded with no errors. Probes confirm constant 30fps, 3840×2160, yuv420p, BT.709 and stereo AAC at 48kHz. No black frames were detected. Decoded frames, including both sides of scene cuts, were inspected: immersive ranges fill the frame with the room/window/controls hidden. Studio’s freeze-detector findings are expected UI holds before the immersive range; no immersive freezes were detected. Logs, frame samples, hashes and complete probes are in `previews/qc-v2/verification.json` and Studio’s `previews/qc-v3/verification.json`. The v3 render and QA processes exited 0. Its review inspected 42 decoded frames across all 14 shots and both sides of each edit. The Studio browser editor remained blank with Play disabled after its restart, so no new browser play-through is claimed; the verified MP4 is the review artifact. Its six narration clips and music were verified in the encoded output by waveform correlation. These are measurement and frame-review results, not a subjective audio listening or exact music-waveform-sync claim.

The initial strict export failed safely on duplicate music automation: a legacy volume attribute hid the valid versioned carve lanes. The old fade points were merged into the version-1 envelope, retaining the spectral carve and ducking. All three checks then passed, and all three strict delivery renders completed using hardware GPU `drawelement` capture.

No upload acceptance is claimed. Apple lists 3840×2160 for Vision Pro previews, while its generic encoding table specifies H.264 up to High 4.0, 10–12Mbps and AAC 256kbps. These quality masters use the valid 4K H.264 High 5.1 profile at approximately 18–59Mbps and AAC 192kbps. Confirm or conform submission encoding against App Store Connect before upload; do not relabel 4K video as Level 4.0. The approved edit and original masters remain preserved.


## Variety revision and immersive toolbar

All three revised compositions are rendered and verified, using the owner’s existing approval to render all three and the subsequently requested changes. All three checks passed after preparing smaller 4K30 source clips. An initial one-frame-short VFR conversion was corrected: all 23 prepared clips now have exact frame counts and durations and pass full decoding. Snapshots covered every shot in the 12-effect montage and the Studio/Radio scenes. The first and Studio immersive selections use disjoint native scene IDs, and Radio’s full-immersion range uses another distinct sequence. Blue, green, gold, purple and mixed palettes were inspected; this is not a single-purple presentation. Footage remains the real simulator output with no grading or fabricated camera movement. Capture settings use the actual Studio paths: one-bar scenes, Chaos 0.85, zoom speed 2, motion speed 1.3, strobe off. The included instrumental bed and existing selected narration remain in the first two previews. Radio’s new bed comes from the same “Neon Tidewater” track visible in the recording; alignment is estimated from transport/capture marks, not claimed waveform-perfect.

`source/variety-revision/` holds the native 3840×2160 recording, original timestamps, real scene grids, isolated project snapshots, Radio track provenance and capture-test logs. Both opt-in capture tests passed with zero failures (127.6 seconds); their runner was stopped after post-suite cleanup stalled. These debug captures require `SWIFT_ACTIVE_COMPILATION_CONDITIONS="STORE_BUILD DEBUG"` and `-PCUITesting`; ordinary launches and release builds do not apply the capture sequence. The user's own projects and soundtrack were not used.

The immersive toolbar is now one centered horizontal row. Vertical separators group song controls, visualizer controls and viewing controls. The hearts explicitly say “Save song” and “Save visualizer”, changing to “Song saved” and “Visualizer saved”. Song titles and visualizer names stay on one line; edge smoothing moved into Viewing settings. The final UI test passed with normal test-command exit 0, verifying independent favorite actions, unchanged state of the other heart, button-center alignment within 3 points and paused controls remaining visible beyond the auto-hide interval. Simulator screenshots are in `source/variety-revision/immersive-controls-saved-and-aligned.png` and its detail crop. This toolbar update is included in TestFlight 1.0 (9); no public App Store submission was made.

## Vision Pro ratings and support

The info button opens **About & Support**, with a native glass panel and two tabs: **Ratings & Support** and **Legal & Credits**. The support page offers **Rate on the App Store**, **Tip the Developer**, **Share PulseCanvas**, and **Send Feedback**. It reuses the Mac app’s `CreatorEngagement`, exact PulseCanvas URLs and storefront policy; the tip link is shown only when the real Apple storefront permits it (currently USA). An unknown storefront does not enable the link. The page uses large cards, gives rating priority, retains local click checkmarks and allows resetting those checkmarks. Opening a link is not recorded as a completed review or payment. Sharing uses the native system share sheet. The existing license text, source link and LLC credit remain available in Legal & Credits.

A successful Files save—not rendering or a canceled/failed picker—advances the review milestone. The same completed movie saved again counts once; a distinct render counts separately even when its content matches. On the second saved render, the app waits until the export sheet is closed and the editor is active and idle, then delays 11 seconds before making its one native StoreKit review request. Leaving a fourth Radio session can request that same one-time review instead; requests never interrupt playback or immersion. This does not display a custom automatic rating nag. Apple controls whether a native rating sheet appears, and suppresses these requests in TestFlight. The explicitly opened App Store review link remains available.

Verification: shared engagement tests passed for Store and direct modes; save handoff tests passed, including duplicate-save and identical-content new-render cases. The Vision support UI test passed with zero failures in 48.201 seconds, checking action availability/hit areas, opening Credits and returning to Studio. A fresh screenshot repeat also passed with zero failures in 50.362 seconds. The earlier test runner stalled after the completed suite and was interrupted; no normal exit-0 test-command claim is made. The final Release simulator build succeeded, and bundle verification confirmed exact native asset bytes, matching legal/privacy resources and no external engine or assets. Website, tips and feedback URLs returned HTTP 200. Native StoreKit presentation, external payment completion and physical-headset interactions were not tested. These changes are included in internal TestFlight 1.0 (9); no public App Review submission was made.

The real export/save recording used an isolated eight-second excerpt of the included soundtrack through a debug-only capture hook. The capture test completed with `TEST SUCCEEDED` in 68.165 seconds and verified the actual “Video saved” result. Source footage, timestamps, test/build logs and the native support-panel screenshot are in `source/studio-save-revision/` within the local asset package. User audio, projects and favorites were preserved. `-PCCaptureAudio` is read only with `DEBUG` and `-PCUITesting`; release builds do not apply the capture fixture.

Apple references: [review request behavior](https://developer.apple.com/documentation/storekit/appstore/requestreview(in:)-4r0y9), [external purchase links](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase).

## Remaining before submission

1. Resolve final submission encoding/acceptance against Apple’s preview specifications; the revised 4K masters and output verification are complete. Earlier approved masters remain preserved.
2. Apply verified copy to the Vision-specific listing, select build 1.0 (9), and upload approved screenshots/previews. Do not change the Mac review submission.
3. Verify required motion information, privacy and age-rating declarations and reviewer fields against the actual app. Check export/save, targets, immersion comfort and sustained performance on a physical headset; simulator checks do not establish those results.
4. Submit only when authorized. Keep the separate website draft and marketing films unpublished until the owner confirms the app is live and supplies the Vision Pro App Store URL.

Apple references: [preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications), [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), [visionOS submission guidance](https://developer.apple.com/visionos/submit/).
