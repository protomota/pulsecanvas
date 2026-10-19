# Vision Pro 1.0 (7) — TestFlight

Delivered October 19, 2026. App Store Connect reports **VALID / IN_BETA_TESTING**
for build `df9390d5-c378-4cb2-a7ca-248370eb0740`. Tester notes were read back
exactly and the existing PulseCanvas Mac Beta group retained all 21 previous
builds (22 total).

- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/df9390d5-c378-4cb2-a7ca-248370eb0740)
- Archived source: `c5119e2f3ed808551674c5d00664106b78ae2f68`
- Native effects: 336; app/bundle: `6821642700` / `com.protomota.pulsecanvas`

## Changes

Studio has a Randomize timeline button beside Apply to all. Its confirmation
sheet offers visualizers, 1–8 bar lengths, or both for the entire song. The Mac's
scene dealer supplies the same category/favorites pool and repeat policy. The
operation commits atomically, preserves shared visual styles, soundtrack and
playback position, and saves the result. Visualizers-only preserves exact imported
cuts and clip IDs; bar changes use the audio bar grid and refill the whole song.

Visual controls use a three-column scrolling slider grid: Chaos, zoom/motion
speed, brightness, effect-specific size, depth/fog, camera zoom/rotation and blur.
Native detail/count controls appear where supported. All are continuous sliders
except integer Halo count. Strobe keeps its label/switch together with sensitivity
and strength sliders below. The size range now accepts the Mac UI's maximum of 6.
Import audio, Open project and Save project show their names in the bottom
ornament; Save project uses a disk icon instead of a share icon.

## Verification

- Project tests passed: random lengths on all generated cards, complete bar-grid
  coverage including decoder padding, retained identities/order/looks, invalid
  length rejection and size-6 JSON round trip.
- Transport tests passed: full-timeline assignment, unchanged imported cuts,
  shared-style renderer bindings, playback position, atomic empty-pool failures,
  bars-only ordering, one-favorite repeats, complete coverage and autosave.
- Targeted simulator XCTest reported zero failures: grid row alignment, required
  sliders, Save project label, timeline confirmation, cancel and successful
  randomization/dismissal. Xcode then stalled for several minutes during post-test
  cleanup, so its process was terminated after the passing suite. This is not a
  claim that the UI-test command exited normally.
- Final Release device archive, distribution export and actual IPA verification
  passed (exact native assets, icons, legal/privacy, signature and profile).
- Apple validation/upload succeeded; API verified processing, group membership,
  prior builds, tester notes and internal availability.
- Actual simulator layout inspected. Physical headset testing was not performed.
  Encoding/save/interchange suites were not repeated; those pipelines are unchanged.

Mac 1.1.4 remains WAITING_FOR_REVIEW. No public App Store submission or website
release was made by this delivery. The marketing version is now 1.0 as requested.

## Local evidence

`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/1.0-7/`

- IPA: `vision-export/PulseCanvas Vision.ipa`, 10,574,280 bytes
- SHA-256: `7dab6d178454895f583ab2fcf84f5365d65377350cba6d79c6cd8968766dc2f7`
- `vision-delivery-receipt.json`, `vision-bundle-verification.json`,
  `validation-summary.json`, `vision-testing-final.json`, group before/after,
  tester notes, logs and `vision-studio-grid.png` remain outside Git.
