> Historical handoff preserved during the 2026-10-14 reconciliation. Current main has 270 active designs / 390 permanent slots; see `docs/MAIN-INTEGRATION.md` for the current state. Counts and merge status below describe the earlier worktree.

# Handoff prompt: merge the PulseCanvas native-visualizer work

Paste everything below the line into the agent that will merge this work into its own.

---

You are merging another agent's work into yours in **PulseCanvas Studio**, a macOS music visualizer built with Swift and Metal. Read this whole prompt before touching git. The owner is Brad.

## Where the work is

- **Worktree:** `/Users/brad/Documents/GIT_SOURCE/pulsecanvas-studio/.claude/worktrees/native-visualizers-100`
- **Branch:** `worktree-native-visualizers-100`. Its base is `main` at `9ebc9d9`.
- **Nothing is committed.** Everything sits uncommitted in that worktree: about 80 modified, 71 deleted and 56 new paths.
  - Run `git status --short` there for the list.
  - To merge with git, someone must commit it first. **Brad must approve any commit or push.** If it isn't committed when you start, ask Brad; don't commit it yourself.
- **The worktree mixes in work from other agents.** The visualizer work is described below. These paths came from other agents, and Brad decides whether they ship with it:
  - **Sparkle direct-release updater:** `Sources/PulseCanvas/AppUpdater.swift`, `macOS/DirectRelease.json`, `scripts/prepare-sparkle.py`, `scripts/sign-direct-release.sh`, `scripts/build-direct-release.sh` and `docs/DISTRIBUTION.md`
  - **Marketing and App Store images:** `assets/marketing/` and `assets/app-store/feature-cards/`
  - **Experiments:** `experiments/metal-studies/`
- **`.build/` is gitignored, so none of it travels with a merge.** Local-only material you may want to read in place:
  - `.build/metal-curation/before-prune/`: the shader sources before the owner's curation
  - `.build/deliverables/Metal-Effects-Review-2026-10-13/`: the review videos with Brad's red Finder tags
  - `.build/patches/`: one-off helper scripts, including `final_suite.sh`, `restore_helpers.py` and `registry_check.py`

## What the work does

1. **Removed copied code.** Released IDs 0–3, 5–9, 11 and 13 reproduced another app's point formulas, mesh kernels and compiled OpenGL/AIR shaders. 14 drew points with those shaders, and 30 duplicated 22.
   - Those IDs are retired.
   - The recovered code is deleted: `SurfaceGeometry.swift`, `MeshGeometry.swift`, `Resources/VisualShaders/*.ll`, `scripts/reference/`, `docs/native-decompilation/`, `scripts/build-shaders.sh` and their tests and fixtures.
   - The renderer no longer loads a metallib.
2. **Added native Metal designs.** IDs 31–99 are procedural designs and 100–199 are tunnels, drives and dances. 200–299 are the main checkout's unpublished development designs, imported under new IDs; the mapping is in `docs/native-import-mapping.json`.
3. **Music drives the visuals.** Every design moves local elements from four band envelopes, an attack swell, momentum and a music clock. **Chaos** gates every one of those inputs: at zero Chaos the output is pixel-identical to silence.
4. **Brad curated the catalog** on 2026-10-13. 181 designs are offered and 119 IDs are withdrawn.
   - Policy and keeper list: `docs/metal-keeper-selection.json` and `docs/METAL_REVIEW.md`.
   - The curation deleted the fragment functions of withdrawn designs.
   - Brad kept 245 Saffron Spindle and 259 Golden Gyre even though an automated similarity pass had called them near-copies. His keep stands.

## Merge rules: break any of these and saved projects or the release break

1. **A registry index is a permanent identity.** Each design's position in `NativeEffects.all` (`Sources/PulseCanvas/NativeEffects.swift`) is its saved ID, `native:<index>`.
   - Never insert, reorder or delete entries. Append only, so anything new starts at **300**.
   - If your branch also defines native designs at 31–299, don't renumber either side. Append yours at 300+ and record the mapping, the way `docs/native-import-mapping.json` does.
   - Check that file first: if your designs are the main checkout's 100–199 set, they are already here at 200–299. Don't import them twice.
2. **Withdrawn IDs stay reserved.** Each is a `.retired(name, icon:, replacement:)` entry whose replacement must be an offered design.
   - Saved projects, Studio timelines and favorites resolve through `NativeEffects.resolved(_:)`, `ProjectMPresets.migratedScene` and `isRetiredScene`. `RenderState.scene`'s didSet also resolves.
   - Don't bring back a withdrawn design unless Brad asks.
3. **The deleted copied code must stay deleted.** If your branch edits or depends on any file deleted in item 1 above, the deletion wins. Re-implement what you need as original code in `OriginalGeometry.swift`, `Canvas.metal` or a `Native*.metal` file. PulseCanvas can't ship code copied from another app's OpenGL visualizers or shaders.
4. **Shaders compile one file at a time.** Each `Resources/Native*.metal` file is compiled at runtime after a prelude:
   - `NativeExpansion*.metal` files use `NativeExpansionCommon.metal`; every other file uses `NativeCommon.metal`.
   - A compile error **silently disables only that file's designs** (`nativeCompileErrors` in `VisualizerRenderer.swift`), so `swift build` won't catch it. Only the tests will.
   - New files must be listed in `NativeEffects.shaderFiles` and the file constants near the top of `NativeEffects.swift`.
5. **The music rules are enforced by tests.** Zero Chaos must equal silence, pixel for pixel (`test-chaos.sh`). Music moves local elements, not the whole frame (`test-audio-sync.sh` and `test-organic-pulse.sh`). The canvas must stay filled in 16:9, 4:3, 3:4, 9:16 and 1:1 (`test-canvas-coverage.sh`).
6. **External presets sit after the native catalog.** Their numeric indexes start at `nativeSceneNames.count`, so they move whenever the catalog grows. Restore by stable identity (`native:<id>` or the preset identity), never by count. `ProjectMPresets.availableScenes` is stored and rebuilt in `rebuildNames`.

## Likely conflict hotspots

- **`Sources/PulseCanvas/NativeEffects.swift`:** the registry, `timelineOrder` (Studio's automatic order, which lists offered IDs only), `activeIDs` and `defaultScene` (= `timelineOrder[0]`, 101 LED Corridor).
- **`VisualizerRenderer.swift`:** per-file shader compile, the canvas point pipeline for 18 and 19, `spatialScenes`, `musicZoom` and `visualPulse`.
- **`ProjectMPresets.swift`, `StudioStore.swift`, `VisualizerPresetStrip.swift`, `VisualizerBrowser.swift`, `StudioTimelineView.swift` and `PulseCanvasApp.swift`:** all of them use `availableScenes` / `activeIDs` instead of ranges.
- **`Resources/Canvas.metal` and `Resources/SpatialVisuals.metal`.**
- **Build and packaging scripts:** `build-app.sh`, `prepare-store-resources.sh`, `package-store-source.sh`, `validate-store-artifact.py` and `preset-provenance.py`. None of them calls `build-shaders.sh` any more.
- **Docs:** `README.md`, `docs/NATIVE_VISUALIZERS.md` (the full catalog and retired table), `docs/RENDERING.md` and `docs/USER_GUIDE.md`. All of them say **181**; update the counts if the merge changes the offered total.

## Verify after merging (from the merged checkout)

1. Run `swift build`.
2. Run `python3 scripts/native-visualizer-catalog.py > /dev/null`. It asserts unique names and icons, and that every retired ID opens an offered design.
3. Run the full suite, excluding the 38-minute OpenGL preset audit:
   ```bash
   scripts/run-validation-suite.sh $(cd scripts && ls test-*.sh test-*.py | grep -v test-preset-playback.sh)
   ```
   - It writes results to `.build/validation/suite/summary.txt`.
   - Before the merge, this suite passed **30/30** on the 181 catalog.
   - The projectM tests need `.build/projectm`; build it with `scripts/build-projectm.sh` if it's missing.
   - If other agents are editing the same checkout, run from an rsync'd snapshot. That's what `.build/patches/final_suite.sh` does.
4. **Smoke tests hard-code a few design IDs** (for example 10, 18, 19, 22 and 31). If the merge withdraws one of them, the test traps with exit code 133. Point it at an offered design of the same kind; don't weaken the check.
5. Update `scripts/NativeMigrationSmoke.swift` if the merge changes which IDs are retired.

## Known open items (not regressions)

- **Lotus Resonance (15) at zero Chaos.** After heavy raymarched frames, about 30 pixels can rarely differ by ±1/255. The cause is screen-derivative normals in `canvasFragment`. This flake didn't occur in the last two runs.
  - A tested option is averaged mesh normals for scene 15 only; the patch is `.build/patches/lotus_normals.py`. Another is test tolerance. Brad hasn't chosen.
- **4K timing.** 46 Crystal Orchard takes about 29.5 ms per frame on a shared GPU. Re-time it on a quiet machine with `scripts/native-gallery.sh timing --size 3840x2160`.
- **`test-preset-playback.sh`** (the direct edition's OpenGL projectM pack) reports 93 of 7,838 presets below its quality thresholds. That predates this work.
- **Stale material:**
  - The contact sheets in `docs/native-visualizers/` predate the curation (they show 285–287 designs).
  - Lines 1–4 of `NativeDrive.metal` hold a stray comment left by the prune.
- **`HANDOFF-native-visualizers.md`** is the long history. Its "Latest state" section is current; read the older counts as history.

## Constraints from Brad

- Ask before any commit or push. Commit format: `[scope] short imperative description`.
- Don't upload releases, change signing, deploy the website or alter distribution channels.
- Never echo secrets.
- Don't create new visualizers unless he asks.
- Keep cheesy literal imagery out of new work (dancing people, cartoon robots, tube men, game arrows).
- When you hand Brad a manual task, give exact URLs and click-by-click steps.

When the merge is done, report to Brad:
- the offered and retired counts
- the suite summary line by line
- any ID you remapped and why
- anything from the "mixes in work from other agents" list that you left out
