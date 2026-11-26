# Vision Pro 1.1.5 (12) — Radio media refresh

October 19, 2026. The third App Store preview now uses a fresh native simulator
recording of the current Radio interface: Studio/Radio stays at the upper left,
visualizer controls sit above the large preview, and song/station and playback
controls sit below. The Electronic station plays “Neon Tidewater”. Song favorites
are demonstrated before 14 seconds of varied full immersion. The existing Emma
narration, soundtrack mix, timing and remaining immersive footage are retained.
Two matching Radio screenshots replace the outdated ones; the other four
screenshots and first two previews are retained.

## Submission history

The earlier Vision submission `9f64771e-c704-43fd-8f8d-32a6be418d61` was voluntarily
canceled to replace the media. Its temporary `DEVELOPER_REJECTED` state was not an
Apple App Review rejection. No new binary is required for these listing/media
changes: the selected build remains 1.1.5 (12),
`1f51a7aa-9dfb-44f7-a4fd-f220dfc9404a`.

The first replacement master reached upload completion and video processing
without a reported encoding error, then disappeared from both a fresh asset list
and the browser. A direct asset read returned 404. The cause was not established;
this is not recorded as an Apple encoding rejection. The verified high-quality
master is preserved. A fresh H.264/AAC delivery file was encoded from it with
fast-start layout and approximately 12 Mbps total bitrate, then uploaded as
`03-PulseCanvas-Radio-Current-UI-AppStore-4K30.mp4`.

## Resubmission

Resubmitted October 19, 2026 at **4:25 PM EDT**. Fresh API reads and the visible
review detail confirm `WAITING_FOR_REVIEW` for both the version and submission,
with build 1.1.5 (12) selected.

- [Submission detail](https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/fb5da144-7a3a-4197-9f29-0f242e45f9f7)
- Submission: `fb5da144-7a3a-4197-9f29-0f242e45f9f7`
- Third preview: `f86a15e1-836f-4c7d-b3af-a3e7a5bf80f7`

All three previews reached upload and video processing `COMPLETE`, with no
reported processing errors or warnings. All six screenshots are `COMPLETE`.
Every uploaded source checksum matches its local file, and their order was
verified. Apple’s hosted Radio player advanced through the current interface
and immersion to `ended=true` at 24.067 seconds without a media error. The
default 5-second poster is retained. This establishes processing and submission,
not App Review approval.

This task did not withdraw or replace the Mac submission. A concurrent update
changed Mac to 1.1.5; its current submission
`ee3c9e5f-5df2-44de-b920-a51c3bee99c7` was verified Waiting for Review. TV remains
a draft. Existing automatic release after approval was retained.

## Verification

- A targeted native capture test selected the requested song and passed with
  zero failures in 75.840 seconds. Xcode stalled after the completed suite and
  was terminated during cleanup; the command did not exit normally with zero.
  The test-only `PULSECANVAS_CAPTURE_SONG` option makes future captures repeatable.
  No application/binary code changed, and isolated test state preserved user data.
- HyperFrames advanced from 0.8.174 to 0.8.177. The composition check passed with
  zero lint, runtime, layout, motion and contrast findings. The strict 4K30 GPU
  delivery render completed with exit 0. No authored animation was changed.
- Master and App Store delivery both contain exactly 720 frames, 24 seconds,
  3840×2160 at 30 fps, yuv420p BT.709, H.264 High 5.1 and stereo AAC at 48 kHz.
  Full decoding passed; black/freeze detection found no intervals. Opening Radio,
  favorites, immersive frames and edit boundaries were inspected.
- Decoded master audio matches the previously approved mix (correlation 1.0).
  No new voice/music generation or subjective listening claim is made.
- The browser composition editor stayed blank with Play disabled; a fresh editor
  play-through is not claimed. Rendered frames and the complete decoded MP4 were
  used for local verification instead. An optional animation-map helper failed
  to initialize its bundled dependencies; it is not counted as a passed check.
- All six local screenshot SHA-256 hashes were checked. Their native 3840×2160
  RGB dimensions and the exact final preview hashes are recorded in the
  [asset manifest](../app-store/vision-1.1.5-assets.json).
- Physical-headset comfort, performance and installation were not tested here.
  No website deployment, external-beta submission or new release binary upload occurred.

## Local evidence

Media package:
`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/Vision Pro/1.1.5/`

The `source/radio-refresh/` directory retains native footage, marks, logs,
prepared-clip provenance, previous screenshots, exact API readbacks and QA data.
`qc-v3/` holds master checks and `qc-appstore/` holds delivery checks. Media,
private audit data and generated build products stay outside Git. The editable
composition is in
`/Volumes/Music/Video/astra_video/videos/pulsecanvas-vision-appstore/03-radio/`.
