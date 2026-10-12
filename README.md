# PulseCanvas Studio

A native macOS editor for making music-synced visual videos. Import a soundtrack, choose a visualizer, shape its appearance, and export an MP4 for social media.

PulseCanvas's first-party code is source available under the [PulseCanvas Source-Available Noncommercial License](LICENSE). Commercial reuse, resale, and commercial forks of that code require separate written permission from Protomota. You may use the official app to create commercial videos; the code restriction does not apply to your exported videos. Third-party components and assets retain their own licenses and copyright notices, including any commercial-use permissions and required LGPL modification/relinking rights; see [third-party sources and notices](third_party/PROJECTM.md). Earlier MIT-licensed releases retain their original permissions.

Cream of the Crop pack curated by ISOSCELES

https://www.patreon.com/posts/pack-nestdrop-91682111

The app menu and Help expose **Legal & Credits** with this confirmed credit and
link. [Preset and texture provenance](Sources/PulseCanvas/Resources/ProjectM/Provenance.md)
records the pinned snapshots, unresolved individual asset permissions, unchanged
upstream notices and manifests for the actual 7,838 presets and 67 texture images.
Attribution does not establish permission from every author. The [official
projectM licensing guidance](https://github.com/projectM-visualizer/projectm/wiki/projectM-Licensing#apple-store-compatibility)
states incompatibility with Apple's stores, including macOS. This is a separate
unresolved release blocker; dynamic linking and matching source do not settle it.

## Create a video

1. Open **Library** to browse the curated preset library and 31 native visualizers. Search names, filter categories and folders, or tap a heart to save your favorites. The horizontal row also offers direct access to every design, with a visible scrollbar for browsing. Clicking a preset keeps your scroll position unchanged; randomization and Studio scene changes reveal the chosen visualizer at the left edge. Playback inside the same section does not reposition the row.
2. The bundled **PulseCanvas** soundtrack loads paused on launch as a 320 kbps MP3. Click **Play** to preview it, **Replace audio** to choose your own track, or remove it for a silent project. Play or scrub the soundtrack to preview its spectral response. **Loop**, beside the waveform on the playback row, starts on each time you launch the app and repeats the track; turn it off to stop at the end. Loop affects preview playback; export always includes the full soundtrack.
3. Choose **Studio** to build a sequence with automatically detected, beat-aligned sections. Click anywhere on a card to select its section. If playback is running, the new section starts playing and looping; if paused, it stays paused at the section’s start. Click its chevron to open the visualizer modal, with search, categories, folders and favorites; choosing a preset closes it, and Cancel leaves the assignment unchanged. The separate play button loops that section continuously until you pause it or choose another section, independently of the full-track Loop switch. **Randomize timeline** opens a dialog with **Visualizers** and **Bar lengths** switches: choose either or both before confirming. Visualizers changes the assignments; Bar lengths chooses 1–8 bars per section on the detected beat grid. Bars alone retains visualizer order, trimming or repeating tail sections to fit the song. Both keep each visualizer’s saved settings. Each card’s shuffle button changes just its visualizer, retaining timing. Sections use the visualizer’s shared appearance settings. Sections are detected automatically when you add a soundtrack. Set **Bars** on each card to choose how long it plays; there is no dragging interface. Canceling the timeline randomization keeps all choices and playback unchanged.
4. Adjust the appearance controls. **Randomize visuals** changes the current visualizer. **Random visualizer** (Command–Shift–R) chooses a different design with its saved settings. Only the dice button randomizes visual settings. Both keep the soundtrack and project settings intact.
5. Open **Project settings** in the toolbar to choose canvas shape, resolution, and frame rate. Canvas options are: 16:9 wide, 4:3 landscape, 3:4 portrait, 9:16 phone, or square.
6. Every export includes the entire soundtrack. Click **Save video** in the toolbar, choose a folder and filename, and save the MP4 there.

Studio starts with four musical bars per card (16 beats). Each card has its own **Bars** control: enter any positive whole number or use minus/plus, so a sequence can use 4 bars, then 1, then 2. Changing one card shifts the following cards along the detected beat grid, retaining their visualizer order. Shortening the sequence adds cards using the last visualizer and the default bar length; lengthening it trims the tail at the song’s end. The final card may contain only part of its requested length. **Apply to all → Bars per section** sets every card to the same bar count and updates the default for new cards; leave its switch off to retain individual lengths. Each bar uses four beats. Audio without a clear beat grid uses a 120 BPM fallback. Per-card lengths are saved with the project, and older projects infer them from their section durations. Visual settings remain shared by visualizer even when different cards use different lengths. Preview and export follow the same timing.

Silent clips are supported too. Without audio, an export is a 15-second silent video. Projects can be saved and reopened. The bundled soundtrack uses a portable reference and remains available on another Mac with the app installed. Imported soundtracks reference their original file, so keep that audio file available.

Short windows use less padding around the toolbar, Studio timeline, and transport. The preview extends into its title/footer space as needed, retaining the project’s aspect ratio and the controls’ 44-point click areas. Larger windows gradually restore that spacing.

## Visual controls

**Lumen Veil** keeps its morphing depth within the camera’s visible range, so zoom and shape changes cannot carry the field behind the camera.

**Blur** softens the whole image evenly without radial smearing at the edges. It defaults to off and is included in visual randomization.

Motion speed, Zoom speed, Chaos, brightness, particle size, depth/fog, camera zoom and rotation, whole-image blur, and five distinct palettes are stored separately for each visualizer. The optional hi-hat strobe adds short white flashes on high-frequency attacks, with adjustable sensitivity and strength. It starts disabled and the randomizer does not enable it.

Each visualizer has a **Zoom speed** slider: set it to zero for steady framing, or increase it for continuous forward travel. **Camera zoom** sets the framing independently. Studio sections and MP4 exports use the same saved settings.

Particle scenes use shaded sphere sprites with visible cores. Scatter Flight travels through a field of large beads. Silk Current forms deep twisting ribbons; Double Twist has faster coils, larger beads, and an orbiting perspective camera. Triangle surfaces use directional lighting and GPU depth testing. Arc Spray forms connected swirling plumes, while Double Twist has coils and connecting rungs. Particle fields travel across the whole canvas, tunnel walls surround the camera, and geometric designs repeat beyond the frame for continuous coverage in wide and portrait formats.

Soundtrack attacks create waves inside the visualizers. **Chaos** controls local swelling and fluid deformation: Mercury Fold’s folds ripple in different directions, honeycomb and square mesh cells stretch in connected waves, and particles and surfaces bend locally. Higher values produce stronger, more varied motion as percussion builds, rather than zooming or jolting the whole canvas on every hit. Quiet passages relax to procedural motion. At zero Chaos, music has no visual effect, including optional flashes; smooth animation, twist, rotation, and configured forward zoom continue. These settings are shared by Studio and exports, and preview volume does not change the response.

The Visualizers tab’s **Present** button, beside **Use at playhead**, shows only the current visualizer full screen and starts the full soundtrack from the current position, honoring Loop. It also works without audio. The visualizer stays selected throughout playback; Space toggles playback, Restart returns to the beginning, and Escape pauses and returns to the editor. Both native and ProjectM effects fill the display using their saved visual settings.

Studio’s **Present** button plays the timeline full screen from the current playhead, following automatic scene changes and each visualizer’s saved settings. It leaves any single-section preview and plays the full soundtrack, honoring Loop. Move the pointer to reveal Play/Pause, Restart, and Exit presentation; controls fade during playback. Space toggles playback and Escape returns to Studio with playback paused. The presentation fills the display; project export settings remain unchanged. Studio cards select and preview a section when clicked; only the separate chevron opens the visualizer picker, and Play and Randomize retain independent buttons.

Both presentation modes offer **Match aspect ratio** in the bottom controls. Check it to fit the visualizer to the canvas shape selected in Project settings, centered with black bars where needed. Unchecked fills the display. This viewing preference is remembered across presentations and launches; it does not change the project or exported video.

Studio’s **Apply to all** button opens common controls for Chaos, Zoom speed, and Motion speed. Select the settings you want to share, adjust their values, then apply them to every visualizer and Studio section. Unselected controls keep their individual values. In the same pop-up, Hi-hat strobe offers **Keep individual**, **Apply all**, and **Remove all**. Apply all enables flashes with your chosen Strobe sensitivity and Flash strength; Remove all switches flashes off everywhere while retaining their saved sensitivity and strength. Zero Chaos still suppresses flashes. Cancel leaves all presets unchanged; shared settings also carry into project saves and exports.

Ultraviolet uses violet and pink, Electric Candy uses bright contrasting accents, Emberlight uses red/orange/gold, Blue Hour uses variations of blue, and Fernlight uses green. Each palette stays within its color stops as the scene animates.

Seven mesh-based PulseCanvas designs add distinct music-responsive forms: Petal Echo, Orbit Loom, Silk Current, Double Twist, Arc Spray, Signal Tiles, and Resonant Shell.

The revised **Bead Surge** (formerly Drifting Beads) flies through a field of large shaded spheres. **Pearl Terrain** (formerly Bead Atlas) travels between rolling pearl surfaces. **Aurora Fold** (formerly Radiant Drift) flows through luminous curtains.

Five more designs add different structures: **Octagon Vault** fills the canvas with a connected, glowing hexagonal honeycomb mesh that flows into a twisting vortex; **Mercury Fold** flows through rippled metallic folds with dark cavities and sharp reflections; its **Liquid detail** slider adjusts the finer texture; **Voltage Weave** bends glowing electrical filaments; **Ink Cyclone** flies through a curved ink tunnel with swirling walls that expand past the camera; **Prism Rain** tumbles through faceted solids. Three further designs add new structures: **Monolith Rush** flies between rising mirrored block skylines; **Halo Engine** travels through staggered groups of independently tumbling metallic rings; **Halo count** selects 1–12 rings per group and **Ring thickness** controls their width; **Tidal Glass** rides a reflective wave chamber. **Grid Vortex** provides a square-cell version of the flowing line mesh, bringing the collection to 31. Both mesh styles expose **Line width**. All twelve spatial designs use a GPU renderer and share the existing palette, Chaos, camera, strobe, Studio, and export controls. Older projects keep their numeric visualizer IDs and settings.

## Export

The renderer samples soundtrack PCM and renders every frame on an indexed timeline. Preview performance does not drop frames from the exported video. Output uses H.264 video in MP4 with stereo AAC audio at 192 kbps. Choose 24, 30, or 60 fps and a 720-, 1080-, or 2160-pixel (4K) shorter edge.

Save video opens the native destination picker before rendering. Export shows the current rendered frame, a wide progress bar, completed/total frames, and a time estimate calculated from the measured rendering rate. The estimate adapts as rendering speed changes; finishing the video and adding the soundtrack are shown as separate stages. The completed MP4 is saved directly to the chosen location. A centered **Video saved** toast offers **Show in Finder**, which also remains available in the inspector after the toast closes.

Metal renders directly into the encoder’s shared IOSurface buffers, avoiding a full-frame CPU copy. GPU completion is awaited asynchronously, and the live canvas stops drawing during export. H.264 hardware acceleration is explicitly requested, with the system encoder retaining its fallback on unsupported hardware. Every frame keeps its selected resolution and timestamp.

| Canvas | 720 setting | 1080 setting | 4K setting |
| --- | --- | --- | --- |
| 16:9 | 1280 × 720 | 1920 × 1080 | 3840 × 2160 |
| 4:3 | 960 × 720 | 1440 × 1080 | 2880 × 2160 |
| 3:4 portrait | 720 × 960 | 1080 × 1440 | 2160 × 2880 |
| 9:16 phone | 720 × 1280 | 1080 × 1920 | 2160 × 3840 |
| Square | 720 × 720 | 1080 × 1080 | 2160 × 2160 |

Rendering can be cancelled. A completed video replaces the selected destination only after rendering and soundtrack muxing succeed; cancelling preserves an existing destination file.

## Build

Requires macOS 14 or later, a Metal-capable Mac, Python 3, CMake, and Xcode with the Metal toolchain. This release was built and checked on Apple silicon with Xcode 27 and Swift 6.4. The app bundles its ProjectM runtime; no separate runtime installation is required. If Xcode reports a missing Metal toolchain, install its official component with `xcodebuild -downloadComponent MetalToolchain`.

```sh
./scripts/build-app.sh
open "build/PulseCanvas Studio.app"
```

The build compiles the checked-in textual shader resources and Swift source, generates an app icon, packages the resources, and signs the local app. The resulting app is in `build/PulseCanvas Studio.app`. Distribution signing and notarization are not configured.

## Checks

```sh
./scripts/test-geometry.sh
./scripts/test-original-geometry.sh
./scripts/test-family-geometry.sh
./scripts/test-point-geometry.sh
./scripts/test-audio.sh
./scripts/test-studio.sh
./scripts/test-compact-layout.sh
./scripts/test-preset-strip.sh
./scripts/test-canvas-coverage.sh
./scripts/test-audio-sync.sh
./scripts/test-rhythm.sh
./scripts/test-chaos.sh
./scripts/test-organic-pulse.sh
./scripts/test-zoom.sh
./scripts/test-blur.sh
./scripts/test-lumen-visibility.sh
./scripts/test-spatial-visuals.sh
./scripts/test-visual-performance.sh
./scripts/test-strobe.sh
./scripts/test-renderer.sh
./scripts/test-offline-renderer.sh
./scripts/test-social-export.sh
./scripts/test-export-feedback.sh
./scripts/test-encoder-surface.sh
```

Rendering checks execute the Metal pipelines and inspect output pixels. Canvas checks measure both-axis span, visible area, occupied regions, motion, and deterministic scrubbing across wide and phone proportions, several times, and varied framing. Playback checks cover Loop off, repeat, pause, disabling, clearing a track, exact section selection, continuous section looping with Loop off or on, and resuming the full soundtrack. Export checks decode the resulting videos to verify dimensions, frame counts, timestamps, codecs, full soundtrack duration, cancellation, and destination handling. Detailed geometry, shader, and validation notes are in `docs/`.

## Current limits

High-frequency onset detection responds to sharp spectral attacks, which can also include cymbals and other treble percussion; it is not an instrument separator. An exported flash is limited by the selected video frame rate. Camera presets, procedural textures, and some mesh/profile choices are approximations, as described in the rendering notes. Project files reference imported audio locally or the built-in soundtrack by its stable identifier.

The curated library includes 7,838 ProjectM effects alongside the 31 PulseCanvas visualizers. All bundled effects have unique two-word display names and icons drawn from a shared set of 120 geometric, orbital, waveform, energy, and atmospheric symbols. Original creator titles remain searchable and appear on hover; stable preset IDs keep favorites and Studio assignments unchanged when display names change. **Library** searches all bundled Milkdrop presets by name, creator, or folder. Choose a category and a subfolder to narrow the list, tap hearts to save Favorites, and use **Surprise me** to pick from the current results. Favorites also appear in each Studio clip’s visualizer selector. Favorites stay local between launches. **Save project** exports your shared visual settings, Studio timeline, and soundtrack reference in a `.pulsecanvas` file; **Open project** restores them. Audio and visualizer source files are not embedded. There is no separate visualizer preset import/export control. Previously installed custom packs remain readable for existing projects. Projects retain stable effect identifiers so Studio clips keep the correct preset when library contents change.

The ProjectM engine is compiled from the included source using CMake. It runs in its own OpenGL context and shares GPU frames with the Metal compositor through IOSurface. Preview, full-screen Studio presentation, and MP4 export use the same engine and soundtrack PCM. Presets retain their own colors, waves, shapes, and feedback; shared Chaos, motion speed, zoom, brightness, camera, blur, and hi-hat strobe controls still apply. Chaos zero feeds silence to ProjectM while its procedural motion continues. Particle size and fog are controlled by the preset itself. This engine is stateful: scrubbing restarts feedback, so a scrubbed frame can differ from continuous playback at the same timestamp. Offline export advances one frame at a time from the beginning of each section.

`./scripts/build-app.sh` builds both engines and packages the app; it requires CMake and Xcode command-line tools. ProjectM source, upstream notices, and pinned versions are documented in `third_party/PROJECTM.md`. `scripts/test-projectm-pack.sh` checks loading and GPU rendering for the complete bundled pack. The collection is curated for visible, moving output and usable playback. Presets with blank, frozen, or sustained white output are removed after individual retesting. Effects with hundreds of custom-shape instances are excluded as a family because their separate OpenGL draw calls stall playback on this Mac; the Core Mirror and transition-only families are also excluded. User-reported unsuitable presets are removed even if automated pixel checks pass. `scripts/test-preset-playback.sh` audits sustained rendering; `docs/preset-compatibility.json` records the packaged counts and criteria. Successfully parsed source files retain their original equations and shaders.

Run `python3 scripts/preset-provenance.py` to verify the entire bundled subset,
hashes, catalog mapping, notices and separate texture inventory. Add `--generate`
with `--presets-checkout PATH --textures-checkout PATH` to regenerate against Git
objects at the pinned upstream commits. `--app PATH --source PATH --revision SHA`
inspect the actual packaged resources and matching source archive. Source
packaging uses a version/build/revision filename to preserve older release
archives and includes the unchanged engine snapshot and rebuild scripts.

The preset row creates only visible controls, so large jumps do not lay out thousands of buttons. ProjectM previews use at most 1,280 pixels on their longest side, then Metal scales them to the canvas. MP4 export renders at the selected resolution, including 4K. These checks cannot judge every aesthetic defect; passing a render test does not guarantee that an effect will look good with every song.

**Favorite** beside the preview title adds or removes the currently playing design from Favorites without opening the library.

In the **Visualizers** tab, **Use at playhead** assigns the current design and its shared settings to the Studio section containing the current song position. It creates detected sections if necessary, keeps their boundaries fixed, and leaves playback and browsing in place. Projects and saved visual settings migrate by stable identities when the library is curated. Sections using retired bundled effects fall back to Octagon Vault; missing user-imported packs still produce an explicit error.

Each Studio card has a dice button beside its visualizer shuffle. The dice rolls the same shared appearance settings as the visual-style inspector, keeping the chosen visualizer. Both shuffle and dice restart and play the card's audio section. All sections using that visualizer share the updated style. Cards are wider to fit the name and separate controls on one row.

## After your second video

After the second successful MP4 save, a one-time thank-you sheet explains Protomota's free-software approach and offers sharing the app and feedback. The successful-save count survives relaunch; canceled or failed exports do not count, and the first save shows only the video-saved confirmation. Direct-download builds and U.S. App Store storefronts also offer an optional developer tip at https://pulsecanvas.si/tips, opened in the browser. Store builds use StoreKit's actual storefront and omit the tip button/payment call to action for other or unknown storefronts. This follows the clearly permitted U.S. case in [Apple's payment rules](https://developer.apple.com/app-store/review/guidelines/#in-app-purchase); no external-purchase entitlement is configured. The tips page returned HTTP 200 on 2026-10-12.

The sheet waits for the saved-video confirmation and other sheets to close. Dismissing it makes one StoreKit rating-request attempt; Apple decides whether the system review dialog appears (it does not appear in TestFlight). Cancelled or failed exports do not qualify, and subsequent exports do not repeat the prompt. Help also includes a permanent App Store review link. Tips, sharing, and reviews unlock no features and are always optional.
