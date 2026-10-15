# PulseCanvas Studio guide

This guide describes the current original Metal development build: **188 active visualizers**, including **100 new driving, tunnel and dance designs**. It has not replaced the uploaded App Store build. The external preset library and copied implementations are withdrawn. Historical distributions have different catalogs.

## Make your first video

1. Open **Library** to browse the curated preset library and 270 native visualizers. Search names, filter categories and folders, or tap a heart to save your favorites. The horizontal row also offers direct access to every design, with a visible scrollbar for browsing. Clicking a preset keeps your scroll position unchanged; randomization and Studio scene changes reveal the chosen visualizer at the left edge. Playback inside the same section does not reposition the row.
2. The bundled **PulseCanvas** soundtrack loads paused on launch as a 320 kbps MP3. Click **Play** to preview it, **Replace audio** to choose your own track, or remove it for a silent project. Play or scrub the soundtrack to preview its spectral response. **Loop**, beside the waveform on the playback row, starts on each time you launch the app and repeats the track; turn it off to stop at the end. Loop affects preview playback; export always includes the full soundtrack.
3. Choose **Studio** to build a sequence with automatically detected, beat-aligned sections. Click anywhere on a card to select its section. If playback is running, the new section starts playing and looping; if paused, it stays paused at the section’s start. Click its chevron to open the visualizer modal, with search, categories, folders and favorites; choosing a preset closes it, and Cancel leaves the assignment unchanged. The separate play button loops that section continuously until you pause it or choose another section, independently of the full-track Loop switch. **Randomize timeline** opens a dialog with **Visualizers** and **Bar lengths** switches: choose either or both before confirming. Visualizers changes the assignments; Bar lengths chooses 1–8 bars per section on the detected beat grid. Bars alone retains visualizer order, trimming or repeating tail sections to fit the song. Both keep each visualizer’s saved settings. Each card’s shuffle button changes just its visualizer, retaining timing. Sections use the visualizer’s shared appearance settings. Sections are detected automatically when you add a soundtrack. Set **Bars** on each card to choose how long it plays; there is no dragging interface. Canceling the timeline randomization keeps all choices and playback unchanged.
4. Adjust the appearance controls. **Randomize visuals** changes the current visualizer. **Random visualizer** (Command–Shift–R) chooses a different design with its saved settings. Only the dice button randomizes visual settings. Both keep the soundtrack and project settings intact.
5. Open **Project settings** in the toolbar to choose canvas shape, resolution, and frame rate. Canvas options are: 16:9 wide, 4:3 landscape, 3:4 portrait, 9:16 phone, or square.
6. Every export includes the entire soundtrack. Click **Save video** in the toolbar, choose a folder and filename, and save the MP4 there.

## Music and movement

**Chaos** controls response to sound. Higher values create stronger localized movement: folding liquid surfaces, dancing ribbons, expanding cells and animated highlights. Zero removes music-driven pulses, acceleration, deformation and flashes while smooth procedural motion continues.

**Motion speed** controls the design’s own animation. **Zoom speed** controls forward travel; zero stops forward zoom while other movement continues. Some designs travel through their own geometry, while others use the continuous zoom pass. **Camera zoom** and rotation set framing. The size control is labeled for the design’s forms, such as structure scale, line width or particle size. Selected designs provide additional detail/count controls.

Native palettes have distinct colors. Brightness changes exposure; whole-image blur softens the contents. Optional hi-hat strobe inserts bright rhythm accents; sensitivity and strength control its response. Strobe is bypassed at zero Chaos.

**Blur** softens the whole image evenly without radial smearing at the edges. It defaults to off and is included in visual randomization.

Each card uses its visualizer’s saved settings, shared everywhere that visualizer appears. There are no separate per-card visual-style settings. Click a card to select it; its play button previews its audio section. Open its visualizer picker with the dropdown control. The heart picker opens a scrolling list of favorites above the card.

The shuffle control chooses a different visualizer without changing saved appearances. The dice control randomizes that card’s visualizer appearance. Both restart the active section loop. **Use at playhead** in Visualizers assigns the current visualizer to the containing Studio section.

Particle scenes use shaded sphere sprites with visible cores. Silk Current forms deep twisting ribbons; Double Twist has faster coils, larger beads, and an orbiting perspective camera. Triangle surfaces use directional lighting and GPU depth testing. Arc Spray forms connected swirling plumes, while Double Twist has coils and connecting rungs. Particle fields travel across the whole canvas, tunnel walls surround the camera, and geometric designs repeat beyond the frame for continuous coverage in wide and portrait formats.

## Watch full screen

**Present** in Visualizers watches the selected visualizer. **Present** in Studio plays the timeline with automatic changes. The aspect-ratio checkbox preserves the project shape; otherwise the visual fills the display. Space pauses/resumes playback; Escape returns to the editor. Presentation also works without imported audio.

## Export and projects

Export uses the entire soundtrack and the chosen visualizer or Studio timeline. Wide 16:9 supports 3840×2160; phone 9:16 supports 2160×3840; landscape 4:3 supports 2880×2160; portrait 3:4 supports 2160×2880; square supports 2160×2160. Available frame rates include 24, 30, 60 and **120 fps (Experimental)**. The experimental 120 fps option renders twice as many frames as 60 fps; export speed depends on the visualizer, resolution and Mac. Some video players and social platforms may reduce playback to a lower frame rate. Render progress shows frames and an estimated time; the estimate adapts as frames finish.

120 fps changes the exported file; the editor preview retains its existing display cadence. In the Creators edition, some OpenGL feedback presets become much darker at 120 fps than at 60 fps. Keep 60 fps for those presets while the higher-rate option is experimental.

The result is an MP4 with H.264 video and AAC audio. Upload it to your social platform separately. The app saves the file to the destination you choose and provides **Show in Finder**; it does not embed a video player in the editor after export.

**Save project** records shared visual settings, Studio timing and the soundtrack reference in a `.pulsecanvas` file. **Open project** restores them. Imported music is linked to its original file; keep it available. If a project moves to another Mac, you may need to locate that audio. The bundled soundtrack is identified independently of the app installation path.

Seven mesh-based PulseCanvas designs add distinct music-responsive forms: Lotus Resonance, Orbit Loom, Silk Current, Double Twist, Arc Spray, Signal Tiles, and Resonant Shell.

The revised **Bead Surge** (formerly Drifting Beads) flies through a field of large shaded spheres. **Pearl Terrain** (formerly Bead Atlas) travels between rolling pearl surfaces. **Aurora Fold** (formerly Radiant Drift) flows through luminous curtains.

Five more designs add different structures: **Octagon Vault** fills the canvas with a connected, glowing hexagonal honeycomb mesh that flows into a twisting vortex; **Mercury Fold** flows through rippled metallic folds with dark cavities and sharp reflections; its **Liquid detail** slider adjusts the finer texture; **Voltage Weave** bends glowing electrical filaments; **Ink Cyclone** flies through a curved ink tunnel with swirling walls that expand past the camera; **Prism Rain** tumbles through faceted solids. Three further designs add new structures: **Monolith Rush** flies between rising mirrored block skylines; **Halo Engine** travels through staggered groups of independently tumbling metallic rings; **Halo count** selects 1–12 rings per group and **Ring thickness** controls their width; **Tidal Glass** rides a reflective wave chamber. Octagon Vault exposes **Line width**. All eleven spatial designs use a GPU renderer and share the existing palette, Chaos, camera, strobe, Studio, and export controls. Older projects keep their numeric visualizer IDs and settings.

Native Metal designs 31–299 add procedural scenes, from flights through fractals and gothic naves to tunnels (plasma bores, LED corridors, wave barrels, wormholes), drives (night highways, mountain passes, coasters, runways) and dances (dance floors, laser shows, drone light shows, fountains, kinetic mirrors, confetti). The full list is in [NATIVE_VISUALIZERS.md](NATIVE_VISUALIZERS.md).

Thirteen designs from the first release were retired because they reproduced another application's visuals or duplicated another design: Prism Wake, Lumen Veil, Pulse Well, Velvet Passage, Facet Flow, Glass Current, Contour Flux, Recursive Corridor, Spiral Tide, Petal Passage, Vapor Run, Scatter Flight and Grid Vortex. Projects and Studio sections that use them open a similar current design instead; removed designs are dropped from Favorites rather than favoriting a replacement; their other sections, timing and settings are unchanged.

## Export

The renderer samples soundtrack PCM and renders every frame on an indexed timeline. Preview performance does not drop frames from the exported video. Output uses H.264 video in MP4 with stereo AAC audio at 192 kbps. Choose 24, 30, 60, or experimental 120 fps and a 720-, 1080-, or 2160-pixel (4K) shorter edge.

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

The curated library includes 7,758 ProjectM effects alongside the 270 PulseCanvas visualizers. All bundled effects have unique two-word display names and icons drawn from a shared set of 120 geometric, orbital, waveform, energy, and atmospheric symbols. Original creator titles remain searchable and appear on hover; stable preset IDs keep favorites and Studio assignments unchanged when display names change. **Library** searches all bundled Milkdrop presets by name, creator, or folder. Choose a category and a subfolder to narrow the list, tap hearts to save Favorites, and use **Surprise me** to pick from the current results. Favorites also appear in each Studio clip’s visualizer selector. Favorites stay local between launches. **Save project** exports your shared visual settings, Studio timeline, and soundtrack reference in a `.pulsecanvas` file; **Open project** restores them. Audio and visualizer source files are not embedded. There is no separate visualizer preset import/export control. Previously installed custom packs remain readable for existing projects. Projects retain stable effect identifiers so Studio clips keep the correct preset when library contents change.

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

In **Library → Back up favorites**, choose **Export favorites…** to save a portable JSON backup anywhere, including a synced folder. Choose **Import favorites…** in another build or on another Mac to merge it with your current hearts. Import never clears existing favorites. The backup retains stable effect identities, including effects unavailable in the current edition; it does not contain effect source files, music, or visual settings.

Favorites also back up automatically after each change, with a latest file and one snapshot per day for each edition. **Show automatic backups** opens that folder. If the favorites preference disappears, the app restores its edition's latest backup; an intentionally empty list stays empty. Back up to an external or synced folder to protect against losing the Mac or its app data. The App Store sandbox and local testing builds can have separate preferences and storage. A fresh local Creators test build seeds its favorites from the installed Creators app without changing the original app's data.

Click outside **Project settings**, **Library**, **Help**, or a Studio settings/picker dialog to close it. Clicking outside a confirmation cancels it without applying changes. Native save and open dialogs still use their own Save/Open and Cancel buttons.

In the **Visualizers** tab, **Use at playhead** assigns the current design and its shared settings to the Studio section containing the current song position. It creates detected sections if necessary, keeps their boundaries fixed, and leaves playback and browsing in place. Projects and saved visual settings migrate by stable identities when the library is curated. Sections using retired bundled effects fall back to Octagon Vault; missing user-imported packs still produce an explicit error.

Each Studio card has a dice button beside its visualizer shuffle. The dice rolls the same shared appearance settings as the visual-style inspector, keeping the chosen visualizer. Both shuffle and dice restart and play the card's audio section. All sections using that visualizer share the updated style. Cards are wider to fit the name and separate controls on one row.

## Ratings, sharing & support

In the App Store edition, the second successful MP4 save schedules one built-in Apple StoreKit review request, after the saved-video confirmation (about 11 seconds) and when the app is active with no other sheet or full-screen presentation. It does not depend on opening or dismissing the support screen. Apple decides whether to display its sheet; the API has no effect in TestFlight. Failed or canceled exports don't count, and the first save doesn't request a review. The save count and request history survive relaunch. Multiple editor windows count each successful export only once.

Open **Help (?) → Ratings, sharing & support** at any time to see the styled screen. Each action remembers its button click locally on this Mac and displays a checkmark. Clicking Rate opens Apple's write-review page. These marks do not establish that a review, tip, share or feedback submission was completed; Apple supplies no review-completion callback. **Reset saved clicks** clears only those marks. It leaves your projects, soundtrack, favorites, export count and Apple's review-request history intact. It cannot force Apple's rating sheet to appear or reset Apple's display limits.

The Creators/direct-download edition shows its styled reminder after the second successful save and after later successful saves until all available action buttons have been clicked. Dismissing it doesn't reopen it for the same export. Resetting clicks resumes these reminders after the next save. The App Store edition never automatically presents this custom review/support sheet; [Apple requires its supplied review API](https://developer.apple.com/app-store/review/guidelines/#ratings-and-reviews).

The tips action opens https://pulsecanvas.si/tips in the browser. In Store builds it appears only when StoreKit reports the USA storefront; other or unknown storefronts omit it, and a hidden action is never required for completion. Direct-download builds include it. All features stay free regardless of clicks or support.

## Radio and favorite songs

Radio’s top bar shows the current visualizer with its own heart. The heart beside the song title saves that song separately. Both bars fade after three seconds of inactivity during playback and return when the mouse moves; paused playback keeps controls visible. The transport retains its requested Play/Pause state and fixed layout while preparing a skipped track.

Open **Library → Favorite songs** to browse saved songs and click a row to start it in Radio. Radio’s Library also has All songs and Favorite songs tabs, with separate hearts in the song list. Song favorites persist locally across launches with their source and station information. Opening the library while listening does not stop playback.

Removed visualizers are automatically deleted from saved favorites on launch; restoring a backup skips effects absent from this edition’s gallery. Retired designs do not automatically favorite their replacements. Song favorites are checked against their source’s complete catalog and removed when that catalog confirms the song is gone, including an empty catalog. A genre subset, invalid catalog or network failure does not prove removal and does not erase favorites. Cleanup updates saved preferences, so removed entries do not return on the next launch. Original user audio files are never deleted by favorites cleanup.

Radio shuffles songs by default. Each station round plays its favorite songs first in random order, then the remaining station songs in random order, avoiding adjacent repeats. Adding or removing song favorites refreshes the next-song choice and its prefetch without stopping the current song. Each favorite visualizer is used at most once per song, in shuffled order; remaining sections use random non-favorites. Changing favorite hearts or bar lengths keeps the current scene and does not replay favorites already shown in that song. A song with fewer sections than favorites can only show as many as fit. If every available visualizer is favorited and the unique choices run out, Radio holds the last design instead of cycling the favorites.


## Creators updates

A tan download-tray icon appears beside **Random visualizer** when an update is available. Click it to open the existing Sparkle installer. Automatic checks can be changed in Settings; manual checks remain in the app menu. See [Updates](UPDATES.md) for reminder behavior and edition differences.
