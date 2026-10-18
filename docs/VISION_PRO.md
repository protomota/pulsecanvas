# PulseCanvas Studio for Vision Pro

The first native visionOS test target combines an editable Studio window with a
curved immersive viewing screen. It shares all 336 active native visualizers,
permanent IDs, palettes, audio analysis and the Mac's Metal renderer. It includes
no projectM engine, community presets/textures or Sparkle updater.

## Editing and viewing

- Import audio through Files, or start with the bundled demo soundtrack.
- The wider left column uses compact row insets and wrapping titles. The shared
  **Randomize all / favorites / category** menu filters the list and randomizer
  together; its custom pool supports combined category/favorite choices.
- **Random visualizer** replaces the selected section's visualizer without changing
  saved looks. The adjacent dice randomizes only that visualizer's style.
- Tap a timeline card's visualizer heading to open its popover: search the library,
  filter categories/favorites, shuffle visualizers, favorite an effect, or adjust
  its palette, Chaos, zoom and motion. Picker edits target that card even if
  playback advances to another section. Styles remain shared by visualizer.
  Set independent 1–64 bar lengths. Music analysis supplies the beat grid. The experimental add,
  remove and reorder buttons have been removed from the interface.
- Edit palette, Chaos, zoom speed and motion speed. An effect shares its look
  across scenes, as on the Mac; Reset restores its native defaults.
- Play, pause, seek and adjust volume. **Loop soundtrack** defaults on, repeats the
  whole soundtrack and timeline, and saves with the project. Older projects default
  to looping without changing their saved sections or styles.
- Choose **Radio** in the left column, select a station and play. Station names,
  membership and audio come from the same HTTPS R2 JSON directory as the Mac.
  Loading and retry states are visible. Radio shuffles tracks and advances at the
  end of each song instead of looping one track. Its cache and transport are
  independent of the editable Studio project; switching modes pauses the old one.
- The **goggles icon** in the bottom ornament opens an immersive space and hides
  the Studio window. The adjacent, visibly labeled **Hide room** switch (on by
  default) hides passthrough and uses a larger curved
  canvas; switch it off before opening to retain the room. Pinch the visual to
  show/hide its floating controls, or use **Back to Studio** to reopen the editor.
  Controls hide after five seconds during playback. Closing immersion through the
  system also restores Studio. The immersive panel includes playback, shuffle,
  visualizer favorite, Radio next-track, and edge-smoothing controls.
- Ordinary backgrounding pauses playback; hiding Studio for an active immersive
  view does not interrupt its audio.
- Save/open `.pulsevision` project backups. The app also autosaves locally.

Audio imports are copied into this app's Documents directory. Project backups
contain settings and a local audio reference, not the audio itself. Moving a
project to another device requires importing the soundtrack there. Missing audio
falls back to the demo with an explanation. The prototype's document format is
separate from Mac `.pulsecanvas` projects.

## Build and run locally

Requires Apple silicon, Xcode with the visionOS SDK, and a compatible visionOS
simulator runtime. The deployment target is visionOS 2.0; validation used Xcode
27.0 and the visionOS 27.0 simulator.

```sh
bash scripts/test-vision-project.sh
bash scripts/test-vision-transport.sh
bash scripts/test-vision-presentation.sh
bash scripts/build-visionos.sh xrsimulator
# Unsigned device-target compilation, not a distributable package:
bash scripts/build-visionos.sh xros
```

Open `PulseCanvasVision.xcodeproj` in Xcode. Choose the **PulseCanvasVision**
scheme, select **Apple Vision Pro** under simulators, and click **Run**. In Xcode
27, Device Hub hosts the simulator. See Apple's
[Vision Pro interaction instructions](https://developer.apple.com/documentation/xcode/interacting-with-your-visionos-app-in-device-hub).
For hardware, select your connected Vision Pro and use your own signing team.
No certificate or provisioning profile is stored in the repository.

The project generator is `scripts/generate-vision-project.py`; it leaves the Mac
project untouched. `prepare-vision-resources.sh` creates an explicit native-only
resource payload under `NativeAssets`. A top-level folder called `Resources`
must not be used in this flat app bundle: it caused simulator installation to
misidentify the bundle layout.

## Validation and remaining device work

Project tests cover defaults for all 336 effects, stable IDs, mixed bar timing,
shared looks, round-trip serialization, retirement migration and malformed input.
Transport tests exercise the actual demo audio, analysis, seek/play/pause,
timeline editing and autosave restoration in an isolated temporary directory.
They also cross a real audio loop boundary, verify loop-off completion and
persistence, category/favorite/empty/single-item pools, independent style dice,
Radio station/catalog fixtures, automatic song advancement, category-limited
Radio sections and preservation of the user's Studio file. Legacy project
decoding is covered separately. A Metal test verifies the presentation filter's
diagonal edge coverage, flat colors, exact smoothing-off output, bounds and alpha.
Card-picker tests advance actual audio into the next section, then verify edits,
style/reset and randomizers stay on the original card, never seek the playhead,
and safely ignore missing clip IDs.
Mac Store regressions exercise all 336 shaders' beat response and zero-Chaos
behavior. Both visionOS simulator and device-target compilation pass. A simulator
installation launches successfully and displays the native Metal Studio preview.

Simulator button interactions and entering/exiting immersion have not yet been
verified: automated pointer taps in Device Hub did not activate its simulated
controls. Hardware comfort, gaze accuracy, immersive texture orientation and
sustained GPU/audio performance still require headset testing. Compilation and a
visible preview do not establish those results.

This is an early test target, not a production App Store release. Distribution
uses the existing PulseCanvas app record and bundle ID `com.protomota.pulsecanvas`. MP4
export, Mac document interoperability and production store
submission are not included. The native shaders currently
render a 2D screen in 3D space; they are not volumetric environments. The immersive
screen renders at 1920×1080, attempting a new frame every 17 ms. The actual rate
depends on the effect and GPU: at most one GPU frame is in flight, and busy frames
are skipped instead of building a stale queue. The Studio preview is removed
while immersion is active, screen geometry is reused rather than rebuilt on
each appearance update, and the audio feature clock runs at 60 Hz on visionOS.
The edge-aware presentation pass is enabled by default and can be disabled for
comparison; it is not temporal supersampling and cannot guarantee removal of all
shader shimmer. Headset frame-rate and visual-quality comparisons remain unrun.

The bundled Legal & Credits screen identifies Protomota, LLC, links the source
repository, and displays the first-party license. Existing music/asset terms
continue to apply separately.

The layered icon uses the existing full-bleed PulseCanvas image in its background
layer and a transparent front layer. Apple's circular mask now crops the whole
image, rather than revealing an inset opaque square. The original brand image and
the TV icon package remain unchanged. For TestFlight, archive
the PulseCanvasVision scheme and export with an App Store distribution profile
for the existing bundle ID. `verify-platform-bundle.py vision PATH_TO_EXPORTED_APP`
checks the actual signed payload, icons, native-only resources, privacy and legal
notice. Never upload the unsigned device-target compile output.
