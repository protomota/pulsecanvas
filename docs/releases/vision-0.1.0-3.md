# Vision Pro 0.1.0 (3) — TestFlight

Delivered October 18, 2026 to the existing internal **PulseCanvas Mac Beta** group.
App Store Connect reports **VALID / IN_BETA_TESTING**. Tester notes were saved and
read back exactly; all 17 previously assigned builds remain in the group.

- App record: `6821642700`
- Bundle ID: `com.protomota.pulsecanvas`
- Platform: `VISION_OS`
- Build ID: `a470c2a2-b74c-408a-9eda-3bd9fb1f52f5`
- Archived source: `52b323f7f5c7b2aec7a6399d386ce7b1cbdec4a2`
- Native effects: **336**; no projectM, community presets/textures or Sparkle.
- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/a470c2a2-b74c-408a-9eda-3bd9fb1f52f5)

## Changes

The goggles icon in the bottom toolbar opens full screen. The large Watch full
screen button, instructional paragraphs and Native Metal badge were removed.
The room-hiding switch has a visible **Hide room** label in Studio and Radio.

Clicking a timeline card's visualizer heading opens a popover with search,
category/favorites filtering, visualizer selection, favorites, shuffle, style
dice, palette, Chaos, zoom, motion and Reset. Changes remain tied to that card
even after playback advances to another section. Visualizer appearance remains
shared, matching the existing Studio model.

## Verification

- Release simulator build and device archive: passed.
- Transport regression: passed, including real audio playback crossing a section
  boundary before editing the earlier card. Selection, style edits, reset and
  randomizers target the intended card without seeking. Invalid card IDs are safe.
- Existing loop, Radio, category/favorites and Studio storage regressions: passed.
- Simulator resource verification: passed.
- Exported IPA signature, profile, exact native resources, icons, privacy/legal
  files and exclusion of external engines/catalogs: passed.
- Apple validation and upload: succeeded without errors. Processing completed;
  group assignment and internal testing availability verified through the API.
- Simulator layout inspected. Physical-headset gaze/pinch interaction, popover
  ergonomics and immersive performance still require headset testing.

MP4 export and Mac project interoperability remain outside this Vision build.
Mac version 1.1.4 remains **WAITING_FOR_REVIEW**. No public App Store submission,
website release or Apple TV release was changed by this delivery.

## Local delivery evidence

Artifacts remain outside Git under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/0.1.0-3/`:

- `vision-export/PulseCanvas Vision.ipa`: **10,239,637 bytes**
- IPA SHA-256: `2bf4aabd51db1b74851d6ad88369fbdca0b56b3f0d4656365df340fdfc4411e1`
- `vision-delivery-receipt.json`, `vision-testflight-final.json`,
  `vision-group-final.json`, `mac-review-unchanged.json`, and `logs/vision-*`
- `vision-studio-layout.png`: actual simulator layout
