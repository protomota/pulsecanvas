# Vision Pro 0.1.0 (4) — TestFlight

Delivered October 18, 2026 to the existing internal **PulseCanvas Mac Beta** group.
App Store Connect's API reports **VALID / IN_BETA_TESTING**. Tester notes were
saved and read back exactly. All 18 previously assigned builds remain available.

- App: `6821642700`; bundle: `com.protomota.pulsecanvas`; platform: `VISION_OS`
- Build ID / delivery UUID: `ae819f64-2aeb-4b5e-b8fe-34a35d95bcd7`
- Archived source: `ab7ab45b74dc02e44811d722f736961d5be0513a`
- Native effects: **336**; no community presets/textures, projectM or Sparkle.
- [TestFlight build](https://appstoreconnect.apple.com/apps/6821642700/testflight/visionos/ae819f64-2aeb-4b5e-b8fe-34a35d95bcd7)

## Changes

Play/pause, elapsed time, scrubber, duration and volume share one horizontal
center line. Studio uses the same four-beat bar grid as Mac Studio. The previous
one-beat plan could thin fast beats and stretch section durations. Four bars now
consume 16 beats; one-bar sections consume four. Timing edits fill the full song
and trim excess tail cards instead of holding the final effect indefinitely.

**Apply to all** offers independently selected bar length, Chaos, zoom speed,
motion speed, and hi-hat strobe Keep/Add/Remove with sensitivity and strength.
Unchecked settings retain their individual values and palettes.

**Save project / Open project** exchange `.pulsecanvas` files using Mac's actual
Codable model. Native effect identities, exact imported timeline cuts, visual
settings, looping and export format survive file exchange. Legacy `.pulsevision`
files still open. Audio remains a separate reference: **Locate soundtrack**
copies the chosen audio into Vision's sandbox while retaining the imported cuts,
card IDs and looks. Missing audio waits for relocation rather than replacing
the session with the demo. Community effects are rejected on this native target.
This is file exchange, not automatic cloud synchronization. Mac also saves and
restores the optional loop field; older Mac builds can ignore that added field.

**Export MP4** uses the shared Metal/offline encoding pipeline and complete
soundtrack. It supports wide, landscape, portrait, phone and square canvases,
720/1080/2160-pixel shorter edges, and 24/30/60 fps. Wide 4K is 3840×2160;
phone 4K is 2160×3840. Rendering shows frame preview/count, progress and remaining
time. **Save video** opens Files to choose the output destination. The normal
preview renderer is removed while the export sheet is open. visionOS selects
the video encoder internally; the macOS-only encoder specification key is omitted.

## Verification

- Vision project model: passed defaults/categories, legacy appearance migration,
  mixed bars, 120/150/180 BPM timing, full-song refill, unique card IDs, decoder
  padding at the final cut, invalid-file rejection and retired IDs.
- Actual demo soundtrack: passed Mac four-bar cut parity (within 1 ms), identical
  bar grid, a live one-bar section switch, four-bar refill, selective bulk settings,
  strobe removal, invalid input, playback and autosave restoration.
- Existing card-picker, loop and Radio regressions: passed. Portable-project
  audio relocation preserved exact cuts, card IDs and settings.
- Native project file round trip: passed the shared Mac decoder/remapper,
  mixed-bar cuts, visual fields, stable identities, loop/export format and
  bundled/external audio references. Unsupported effect rejection passed.
- Actual shared-pipeline exports on Mac: decoded **1920×1080/60 fps** and
  **3840×2160/60 fps**. Each contained 240 consecutive frames over four seconds,
  nonblack frames across three sections and a full-length AAC soundtrack.
- Vision Release simulator build, device archive, Mac Release regression build
  and Apple TV simulator regression build: passed.
- Generated simulator resources and actual exported IPA: passed native-resource
  byte checks, icons, privacy/legal notices, strict distribution signature,
  matching profile and exclusion of external engines/catalogs.
- Apple package validation and upload: succeeded without errors. Processing,
  internal testing status, additive group assignment and exact tester notes were
  verified through the official API.

Physical-headset export throughput, thermal/memory behavior, gaze/pinch, Files
save interaction and long-form 4K exports remain untested. Desktop export tests
do not establish headset rendering speed. The simulator visibly shows aligned
playback controls and the Apply-to-all button; automated simulator pointer taps
did not activate the modal, so its live interaction is not claimed verified.

Mac 1.1.4 remains **WAITING_FOR_REVIEW**. This delivery did not replace that
submission or release new Mac, website or Apple TV binaries.

## Local evidence

Artifacts remain outside Git under
`/Volumes/Music/Codex Media/PulseCanvas Studio/Platform Builds/0.1.0-4/`:

- IPA: `vision-export/PulseCanvas Vision.ipa` — **10,462,428 bytes**
- IPA SHA-256: `372d69dd13ae3ef6eed1c69c428335437b377e931eedf519c2f5b3cad267c565`
- `vision-delivery-receipt.json`, `vision-testflight-final.json`,
  `vision-group-final.json`, `mac-review-unchanged.json`, `logs/*`
- `validation/`: native project round-trip fixtures and decoded-test MP4s
- `vision-studio-layout.png`: actual simulator layout

An initial verification run hit a full startup disk. Build caches were moved to
the render drive with their original paths preserved by symlinks; affected checks
were rerun successfully. A strict floating-point timing assertion was corrected
to compare the Mac cuts within 1 ms rather than require bit-identical doubles.
