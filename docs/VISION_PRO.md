# PulseCanvas Studio for Vision Pro

The first native visionOS test target combines an editable Studio window with a
curved immersive viewing screen. It shares all 336 active native visualizers,
permanent IDs, palettes, audio analysis and the Mac's Metal renderer. It includes
no projectM engine, community presets/textures or Sparkle updater.

## Editing and viewing

- Import audio through Files, or start with the bundled demo soundtrack.
- Browse native categories, search and favorite effects using gaze and tap.
- Assign effects to scenes, set independent 1–64 bar lengths, and add, remove or
  reorder scenes. Music analysis supplies the beat grid.
- Edit palette, Chaos, zoom speed and motion speed. An effect shares its look
  across scenes, as on the Mac; Reset restores its native defaults.
- Play, pause, seek and adjust volume. Playback drives the same audio features
  used by the Mac renderer and follows the scene timeline. Backgrounding pauses.
- Open **Immersive view** to watch a curved screen in mixed immersion, retaining
  the surrounding room and editable window. Distance and height remain adjustable.
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
export, Radio, Mac document interoperability, production store
submission are not included in this first target. The native shaders currently
render a 2D screen in 3D space; they are not volumetric environments. The immersive
screen renders at 1536×864/30 fps with bounded GPU work in flight.

The bundled Legal & Credits screen identifies Protomota, LLC, links the source
repository, and displays the first-party license. Existing music/asset terms
continue to apply separately.

Layered app icons now use the existing PulseCanvas mark. For TestFlight, archive
the PulseCanvasVision scheme and export with an App Store distribution profile
for the existing bundle ID. `verify-platform-bundle.py vision PATH_TO_EXPORTED_APP`
checks the actual signed payload, icons, native-only resources, privacy and legal
notice. Never upload the unsigned device-target compile output.
