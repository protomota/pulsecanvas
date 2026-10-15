> Historical handoff preserved during the 2026-10-14 reconciliation. Current main has 270 active designs / 390 permanent slots; see `docs/MAIN-INTEGRATION.md` for the current state. Counts and merge status below describe the earlier worktree.

# Handoff: PulseCanvas native visualizers (copies removed, 100 new designs, music response)

You are continuing work on **PulseCanvas Studio**, a macOS music visualizer (Swift + Metal).
Work only in this git worktree, on branch `worktree-native-visualizers-100`:

`/Users/brad/Documents/GIT_SOURCE/pulsecanvas-studio/.claude/worktrees/native-visualizers-100`

Nothing has been committed. **Ask the owner (Brad) before any commit or push.** Do not upload
releases, change signing, deploy the website, or alter distribution channels. Never echo secrets.

## What the owner asked for, in order

1. Expand the native Metal visualizers (done earlier: IDs 31–99).
2. "anything that is a copy remove it including any of the original 31 that were copies. we cant copy the opengl ones" — **done**.
3. "create 100 more make them more vibrant and dynamic tunnels and driving and dancing visuals" — **done** (IDs 100–199).
4. "Try not to be too cheesy… the dancing people might be a little cheesy" — **done**: 17 literal concepts (robots, tube men, puppets, game arrows, silhouette crews…) were replaced by abstract ones in the same IDs. He then briefly asked to keep everything, and then withdrew that: do **not** restore replaced concepts; keep every design that is not a duplicate or near-duplicate.
5. "make sure sound inputs to the visual input connectors… so the sound actually moves the visuals. That's the whole idea." — **mostly done, 24 designs still weak** (see below).
6. "wrap up… don't create more visualizers" — the session stopped here.
7. Owner's keeper review (October 13): every design the owner red-tagged in the review folder is kept; the rest are withdrawn. **This supersedes the counts in the sections below.**

## Latest state: owner-curated catalog (read this first)

- **181 offered, 119 retired** of 300 reserved IDs. The policy and keeper list are in `docs/metal-keeper-selection.json`. A concurrent process (not this agent) applied the curation: it retired the unmarked IDs to 101 LED Corridor and removed 229 unused fragment functions. The pre-prune sources are in `.build/metal-curation/before-prune/`.
- The review **kept 245 Saffron Spindle and 259 Golden Gyre**, which the earlier duplicate pass had retired. The owner's choice stands, so do not re-retire them.
- **Prune fallout fixed:** `NativeDrive.metal` lost `drvBend`/`drvBendSlope` while kept designs still called them, so the whole file failed to compile. The concurrent process then also removed the unused `drvRoad`.
  - All 15 `Native*.metal` files compile after their prelude: `python3 .build/patches/restore_helpers.py`. It also restores any missing helper from the backup if a later prune breaks a file again.
  - `python3 .build/patches/registry_check.py` confirms every offered entry's function exists and every retired ID opens an offered design.
- **Docs updated to 181:** `docs/NATIVE_VISUALIZERS.md` (every withdrawn row is marked, the retired table lists all 119, 245/259 are restored), `docs/RENDERING.md`, `README.md` and `docs/USER_GUIDE.md`. The scripts are `.build/patches/docs_curated.py` and `docs_keepers_245_259.py`, and the originals are in `.build/patches/docs-before-curated/`.
- **Tests on the curated catalog:** see "Curated catalog validation" at the end of this file.

## Current state

- **Catalog:** `Sources/PulseCanvas/NativeEffects.swift` has 200 ID slots: **187 offered designs** and 13 retired.
  - IDs are permanent `native:<id>` identities, so only ever append.
  - `NativeEffects.activeIDs`, `isRetired`, `resolved` and `defaultScene` live there. `defaultScene` is `timelineOrder[0]`, which is 101 LED Corridor.
- **Retired (copies):** 0–3, 5–9, 11 and 13 reproduced another app's point formulas, mesh kernels and AIR shaders. 14 drew points with those shaders. 30 duplicated 22.
  - Each retired ID keeps a `replacement` (see the table in `docs/NATIVE_VISUALIZERS.md`).
  - `RenderState.scene`'s didSet resolves retired IDs. Migration lives in `ProjectMPresets.migratedScene` / `isRetiredScene`, and a retired design's saved style is dropped.
  - The browser, preset strip, favorites, timeline order and random picks use `ProjectMPresets.availableScenes`.
  - The recovered code is deleted (`SurfaceGeometry.swift`, `MeshGeometry.swift`, the `VisualShaders/*.ll` modules, the decompilation docs, reference shaders and their tests), and the build scripts no longer call `build-shaders.sh`.
  - Released 18 and 19 now use an original bead-sprite shader in `Canvas.metal` (`canvasPointVertex`/`canvasPointFragment`).
- **Renamed** (the old names echoed projectM preset titles):
  - 15 → Lotus Resonance
  - 36 → Graviton Petals
  - 79 → Windowpane Drizzle
  - 93 → Mitosis Garden
  - 141 → Neon Trails (to avoid a film-franchise term)
- **New designs 100–199:** six files in `Sources/PulseCanvas/Resources/`, each compiled after `NativeCommon.metal`:
  - `NativeTunnels` (100–116)
  - `NativeWormholes` (117–133)
  - `NativeDrive` (134–150)
  - `NativeRoads` (151–166)
  - `NativeDance` (167–183)
  - `NativeRave` (184–199)
- **Per-file compile:** the renderer compiles each `Native*.metal` file separately. A broken file disables only its own designs and reports the compiler error.
- **Docs updated:** `docs/NATIVE_VISUALIZERS.md` (full catalog, retired table, provenance), `docs/RENDERING.md`, `docs/USER_GUIDE.md`, `README.md`, `docs/ORIGINAL_VISUALIZERS.md`. Dated notes were added to `docs/app-store/LICENSES.md` and `RIGHTS-RESOLUTION.md`, and a historical note to `docs/unused-code-audit.md`.
- **Left alone on purpose:** `docs/app-store/METADATA.md` still describes the submitted 31-visualizer App Store build. Store-listing changes are the owner's call.
- **Edition receipt:** the catalog script now emits `activeCount`, and `prepare-store-resources.sh` and `validate-store-artifact.py` use it.

## Checks and their status

- **Gallery checks:** all pass on the 103 designs touched last: audit (zero-Chaos isolation 0.000), zoomcheck, beatcheck, palcheck, covercheck at 320x180 and 180x320, and wrapcheck. Results are in `.build/validation/final/*2.txt`.
- **Full suite:** last started on a frozen snapshot. Results are in `/private/tmp/claude-501/-Users-brad-Documents-GIT-SOURCE-pulsecanvas-studio/5a15c3d7-3c96-4d0f-973b-f9c9fa486b23/scratchpad/suite-final2/.build/validation/suite/summary.txt`. If that path is gone, re-run `scripts/run-validation-suite.sh`. Run it from a copied snapshot if you are still editing sources: rsync the worktree without `.build` and symlink `.build/projectm`.
  - The previous full run passed everything except the items below.
  - `test-audio-sync` failed on 146 Bullet Train's beat response; that is fixed since.
  - Four projectM scripts were already broken before this work and still don't compile: `test-preset-playback`, `test-projectm-compositor`, `test-projectm-pack` and `test-projectm-transitions`. `ProjectMError` moved to `ProjectMPresets.swift` in uncommitted distribution work, and these scripts compile only `ProjectMEngine.swift`.
- **4K timing:** the agents measured on a shared GPU, so the numbers are noisy. Re-time quietly with `scripts/native-gallery.sh timing --size 3840x2160`.
  - Possibly over 8 ms: 176 Pigment Burst and 180 Fire Dance (8.3 ms when shared).
  - 37 Ion Cathedral was not timed after its music change.

## Update after the handoff was written (08:15)

- **Item 0 is done.** Runway Rush now flares a thin horizon/approach-light band on attacks, and `scripts/test-audio-sync.sh` passes: all scenes visibly pulse without strobe and palette constraints hold.
- **The four old projectM scripts now compile.** A test-only `scripts/ProjectMErrorStandalone.swift` was added to `test-preset-playback`, `test-projectm-compositor`, `test-projectm-pack` and `test-projectm-transitions`. Their run results were pending when this was written.
- **Another agent has since added IDs 200–299** ("existing designs integrated from the main checkout") in `NativeExpansion*.metal`. The duplicate check must now cover those too.
  - For the 187-design catalog, the suite's pixel test found every one of the 17,391 pairs distinct; the closest pair (Arc Spray / Marquee Strip) differs by 13.8/255. A structural-similarity review found no near-duplicates.
  - With the integrated set (287 designs), the closest structural pair is **262 Neon Needle / 270 Violet Velocity (0.904)**. 245 Saffron Spindle / 262 Neon Needle and 294 Crimson Cadence / 296 Coral Crescendo are next.
    - Reviewed visually: 262 and 270 were the same radial web tunnel. **262 Neon Needle is now retired** (replacement 270) and removed from Studio's order. `NativeMigrationSmoke` now expects 14 retired IDs.
    - The other top pairs are different designs that share purple textures. The pair sheet is `.build/gallery/sim-integrated/pairs.jpg`.
    - At 286 designs, `scripts/test-native-expansion.sh` passed: all 40,755 pairs render distinctly, and the closest pair (Double Twist / Arc Spray) differs by 14.1/255.
    - **Full review of 200–299:**
      - The provenance scan is clean: no reuse of the local Milkdrop port prototype, no names echoing preset titles, and no identical function bodies among all 269 effects.
      - A one-sheet visual pass and a within-cluster check found two families: about 12 grid-floor flyovers and about 22 radial spoke tunnels.
      - The grid floors score ≤ 0.78 and look different (square, triangulated, cellular and curved grids), so they are kept.
      - In the radial family, **277 Velvet Wormhole duplicated 259 Golden Gyre (0.859) and is now retired** (replacement 259). The rest are ≤ 0.84 and visibly different.
      - The catalog is now **285 offered designs and 15 retired IDs**. `NativeMigrationSmoke` expects `[…, 30, 262, 277]` and passes.
      - Sheets: `.build/gallery/sim-integrated/{sheet200,grids,radial}.jpg`. Pair scoring: `.build/patches/cluster_pairs.py`.
  - Command: `python3 .build/patches/similarity_all.py .build/gallery/sim-final/t20 .build/gallery/sim-final/t47 .build/gallery/sim-final/t95 --top 30`.

## Final verification (09:30, Claude session)

- **Duplicates:** `scripts/test-native-expansion.sh` on the final 285-design catalog passes. All 40,470 pairs render distinctly; the closest pair (Double Twist / Arc Spray) differs by 14.1/255.
- **Music coverage:** `musiccheck` over all 285 shows none below 12% area.
- **Further coupling** for the weakest Nature designs (`NativeNature.metal`). musiccheck area before → after:
  - 46 Crystal Orchard: 13.9 → 39.5%
  - 58 Kelp Cathedral: 14.8 → 53.0%
  - 59 Solar Filigree: 15.2 → 36.9%
  - 96 Glacier Rift: 13.6 → 66.7%
  - 97 Firefly Meadow: 14.9 → 19.4%

  All five now use the music clock. Audit, wrapcheck, zoomcheck, beatcheck, palcheck and covercheck in both orientations pass on them.
- **4K timing:** 46 Crystal Orchard runs at 29.5 ms (it was already the slowest native design, at 26.8 ms before) and 96 Glacier Rift at 17.0 ms. Both are raymarchers; reduce their step counts if 4K real-time matters.
- **Still under 18% area** (all above 12%): 4 Bead Surge, 26 Prism Rain, 27 Monolith Rush, 85 Ocean Swell, 257 Luminous Nautilus, 258 Indigo Infinity. The first three already move strongly with the music clock (total 42–53).

## Final suite (09:45) and one intermittent failure

- **Result:** a fresh snapshot run passed every test except two.
  - `test-preset-playback`: 93 of the 7,838 projectM presets fall below the visible-output thresholds. That library ships only in the direct-download edition.
  - `test-store-edition`, intermittently: "Zero Chaos leaked music … Lotus Resonance". It also hit `test-chaos` once, and both passed on re-run.
- **Root cause (reproduced):** the probe in `.build/patches/LotusProbe.swift` renders scenes 4, 10 and 12 and then Lotus Resonance (15).
  - Even with no audio at all, the first canvas frame after those heavy raymarched frames can differ from an identical re-render by ±1/255 in about 30 scattered pixels. This happens with blur and zoom off too.
  - So it is GPU-level non-determinism in the OriginalGeometry/`Canvas.metal` mesh path, not music reaching the image. Music has no effect at Chaos 0.
- **Cause confirmed:** with the normal in `canvasFragment` forced to (0,0,1), i.e. no `dfdx`/`dfdy`, the probe shows 0 mismatches.
  - It is the screen-derivative normal on Lotus's roughly one-pixel-wide ring strips. Quads on those triangles occasionally shade differently.
  - Scenes 16 and 21 (wider surfaces) and the native designs are bit-exact.
- **Options (ask the owner):**
  1. Give the canvas meshes per-vertex normals: add a normal to `VisualVertex` (stride 64) and accumulate face normals in `immersive()`. This changes the faceted look of 15–21 to smooth shading.
  2. Let `ChaosSmoke` accept ≤1/255 differences for 15–21.

  Widening Lotus's strips (0.09 → 0.16) was tried and did not help, so it was reverted.
- **Commands:** build and run the probe with the `swiftc` line in this session's history, i.e. the renderer sources plus `scripts/RendererBundle.swift` and the probe. `BLUR=0 ZOOMS=0 .build/validation/lotus-probe 15` reproduces it.

## Complete similarity review (11:05)

- **Coverage:** every pair in the 285-design catalog with structural similarity ≥ 0.85 was listed: 116 pairs involving 35 designs (`.build/gallery/sim-last/pairs.txt`).
- **Review:** all 35 were reviewed visually in their default looks (`flagged.jpg`). The two families that could hide near-copies were then compared in the same palette at two song times (`family0.jpg`, `family1.jpg`).
- **Result:**
  - The tiled-motif family (211, 219, 280, 284, 292, 294, 296) is genuinely varied: stars, overlapping squares, pentagon rings, sharp triangles, soft blobs, flower circles and bokeh. It is kept.
  - Every other flagged pair is unrelated designs that share fine texture. They are kept.
  - The radial web family had two more near-copies, now retired: **245 Saffron Spindle → 249 Fuchsia Furnace** and **259 Golden Gyre → 270 Violet Velocity**. 277 Velvet Wormhole now opens 270, since a replacement must stay offered.
  - The kept web designs are distinct: 249 zigzag web, 255 filled star burst, 270 bright spoke web and 271 target flower.
- **Catalog:** **283 offered designs, 17 retired IDs.** `NativeMigrationSmoke` expects `[0, 1, 2, 3, 5, 6, 7, 8, 9, 11, 13, 14, 30, 245, 259, 262, 277]`.
- **Docs:** README, USER_GUIDE, NATIVE_VISUALIZERS and RENDERING are updated to 283.
- **Tests on the 283 catalog (frozen snapshot):** all pass — native expansion (39,903 pairs distinct; closest Double Twist / Arc Spray at 14.1/255), migration, chaos, store edition, audio sync and Studio.

## Final full suite (10:50)

- **All 30 tests pass** on a frozen snapshot of the final worktree: 285 active designs, including the Nature, Flow and Spatial music edits and the Kelp motes. This covers audio-sync, chaos, store edition, native expansion (distinctness), migration, renderer, zoom, social export, studio, projectM compositor/integration/pack/transitions and provenance.
- **Not run:** the 38-minute `test-preset-playback` OpenGL quality audit. Its last run had 93/7,838 presets below its thresholds.
- **Caveat:** the Lotus Resonance ±1/255 flake (above) is intermittent and did not trigger this time.
- **Results:** `/private/tmp/claude-501/-Users-brad-Documents-GIT-SOURCE-pulsecanvas-studio/5a15c3d7-3c96-4d0f-973b-f9c9fa486b23/scratchpad/suite-final4/.build/validation/suite/summary.txt`.

## Remaining work (priority order)

0. **Fix the one failing suite test first.**
   - The final full run passed everything except `test-audio-sync.sh`: "Beat pulse must visibly change scene 155" (Runway Rush). The four projectM scripts that were already broken still fail as well.
   - The beat test renders at 180x320, time 1.33, with RenderState's default Chaos 0.5. It sends an attack (audioPulse 1, audioSwell 1), which must change more than 100 pixels by more than 8/255.
   - The roads music pass changed 155 and its attack light no longer shows at that size. Add a clearly visible local `c.hit` flare in `NativeRoads.metal`.
   - Check with `scripts/native-gallery.sh beatcheck --scenes 151-166 --size 180x320`, then re-run `scripts/test-audio-sync.sh`.
1. **Music response for 24 designs.** Read `.build/patches/briefs/MUSIC.md` (the targets) and `.build/patches/briefs/RULES.md` (the shader API and rules), then measure with `scripts/native-gallery.sh musiccheck --scenes <ids> --size 192x108`. The target is area ≥ 18% and levels ≥ 6 at default look, with the music clock `c.m` in the main motion.
   - **Drive, already using the clock:** 142 Rally Forest, 143 Bridge Run, 144 Coaster Loop, 145 Hover Lanes (dropped to 3.3% after the clock change; check why), 146 Bullet Train, 147 Apex Chase, 148 Snow Drive, 149 Dashboard Glow, 150 Midnight Skyline. 135 Neon Boulevard is at 16%.
   - **Roads, no clock yet:** 158 Rail Rush, 159 Starlane Convoy, 160 Marquee Strip, 161 Sky Causeway, 162 Turbine Road, 163 Chevron Rush, 165 Glider Valley, 166 Rocket Sled. 152 Canyon Run (14.9%) and 153 Interchange (12.6%) are borderline.
   - **Older designs:** 38 Velvet Circuit, 43 Prismatic Dunes, 51 Paper Cascades, 54 Gyroscopic Garden, 72 Piston Hall, 77 Zen Rake, 87 Murmuration. Their files are `NativeStructure`, `NativeNature` and `NativeParticles`. Backups of all three, taken before the music pass, are in `.build/gallery/music8/backup/`.
   - **Possibly too strong now; check in motion for whole-frame pumping and tone down if needed:** 107 Helix Stair, 103 Hyperloop, 105 Magma Tube, 110 Twist Checker, 157 Bobsled Chute, 173 Conga Orbs, 177 Pirouette Bloom, 37 Ion Cathedral. Use `frames --chaos 1`.
   - **Optional:** 102, 109, 111, 112, 114 and 115 still don't use the music clock in their motion.
2. **37 Ion Cathedral:** run wrapcheck, zoomcheck, beatcheck, palcheck, covercheck and timing. Only audit and musiccheck were run after its change.
3. **Re-run the full suite and update `docs/native-visualizer-validation.md`.** It still describes the 100-design state. Add the musiccheck before/after summary: median area went from 23% to 40%. Also update the validation and performance paragraphs at the end of `docs/RENDERING.md`.
4. **Regenerate the deliverables.** Contact sheets go in `docs/native-visualizers/contact-sheet-{wide,phone,square}.jpg` (via `scripts/native-gallery.sh stills` and `scripts/native-contact-sheet.py`). Motion strips go in `docs/native-visualizers/motion-strips.jpg`. Labeled reels go in `.build/deliverables/`, via `scripts/native-reel.sh` and `scripts/label-reel.py`. All of these currently show the old 100-design catalog.
5. **Optionally rebuild the App Store Xcode project** in Debug with signing disabled. `python3 scripts/generate-store-project.py` was already re-run after the Swift file removals.

## Useful tools

All in this repo; the `.build/patches` scripts are local helpers and are not committed.

- `scripts/native-gallery.sh <cmd> --scenes … --size WxH`. Commands: `stills`, `frames`, `audit`, `wrapcheck`, `zoomcheck`, `beatcheck`, `palcheck`, `covercheck`, `timing`, `musiccheck`. `musiccheck` is new: levels/area are the instantaneous response, and total includes the music clock. The tool rebuilds itself whenever Swift sources change; don't run several rebuilds in parallel.
- `.build/patches/compile_native.sh NativeX.metal`: fast offline compile with file line numbers.
- `.build/patches/sample_song.sh <ids> 224x126` and `.build/patches/song_sheets.py 224x126 <lo-hi>`: eight song-time samples per design, laid out as rows. Use these for visual review, not single stills.
- `.build/patches/music_weak.py <music.txt> 12`: groups weak designs by file.
- `.build/patches/similarity_all.py <dirs…>`: structural similarity. It found no near-duplicates; the top pairs are unrelated busy textures.
- `.build/patches/timeline_order.py --apply`: interleaves Studio's automatic order. It is already applied, and `NativeEffects.swift` keeps the order.
- `.build/patches/docs_catalog.py`: regenerates the 100–199 table and the retired section in `docs/NATIVE_VISUALIZERS.md` from `.build/patches/new_catalog_rows*.py`.
- `scripts/test-native-expansion.sh`, `test-native-migration.sh`, `test-chaos.sh` and `test-store-edition.sh` are the key suites. They iterate `NativeEffects.activeIDs`.

## Owner preferences

- Tasteful and abstract, not cheesy: no literal cartoon figures in new work.
- Vibrant and dynamic.
- Keep every dissimilar design, and remove copies and duplicates.
- Music must visibly move the visuals.
- When handing him manual tasks, give exact URLs and steps.
- He runs a Codex session in the main checkout. That checkout was left on branch `claude/native-visualizers-100` with older copies of this work plus Codex's edits. Tell him so; he may want `git switch codex/distribution-editions` there once Codex is idle.

## Continuation receipt — 2026-10-13

The required weak-design music pass, Ion Cathedral checks, combined catalog integration and default palette update are implemented. Existing main development designs were mapped to 200–299; no additional visualizers were invented. A concurrent duplicate review withdrew 262 in favor of 270 and 277 in favor of 259, leaving 285 active styles. Music drives local surfaces and objects, with 18 ms attack and 95 ms release. Existing saved looks and user soundtrack/session files were preserved. No commit, push, installation or release was performed.

See `docs/native-visualizer-validation.md` for actual results and limits. The optional optimized OpenGL integration test remains unresolved although its unoptimized diagnostic build passes; the long OpenGL quality audit was not completed in this continuation. Metal-only development build and ZIP exclude projectM assets and engine. Final gallery deliverables are under `.build/deliverables/PulseCanvas-native-visualizers-*`; their `.decoded.json` receipts and decoded color contact sheets establish frame and color validation, not licensing clearance or a release signing assessment.

## Curated catalog validation — 2026-10-13 (181 offered / 119 retired)

- **Full suite** (`.build/patches/final_suite.sh <snapshot>`, every test except the long OpenGL preset audit) on a frozen snapshot: **30/30 pass**.
  - In that run, `test-preset-strip.sh` failed only because the test still used withdrawn ID 4; after the fix it passed on re-run.
  - The Lotus Resonance zero-Chaos flake did not appear in either run, but the root cause is unchanged (see above).
- **Tests updated for the curation:** withdrawn ID 4 (and 200 in one list) was replaced with offered designs of the same kind.
  - `StoreEditionSmoke` and `StudioSmoke` (both crashed on ID 4), `PresetStripSmoke` (two places), `CompactLayoutSmoke`, `SocialExportSmoke`, `SpatialVisualSmoke` (4 dropped: it is no longer a spatial design) and `MusicResponseSmoke` (200 → 201; its pass message now prints the integrated count instead of a fixed 100).
- **Not done:** no commit, push, install or release. The long OpenGL preset audit (`test-preset-playback.sh`) was not re-run; it covers only the direct edition's projectM presets and is unaffected by the native curation.


## Owner-authorized Creators release — 2026-10-13

The owner explicitly requested a signed website release of the full-library Creators build for testing. That request superseded this handoff’s previous no-release restriction for this release only. A frozen snapshot in `.build/creators-release-1.0.3` produced Creators Edition 1.0.3 (11), with 181 curated native Metal styles and the preserved 7,838 projectM presets / 67 textures. The app is Developer ID signed; Apple notarization 6966ad07-1749-4c7d-b065-3e513152cc90 is Accepted. The final DMG is stapled, Gatekeeper-accepted, and Sparkle signed/verified. Installer inventory and provenance hashes passed. Optimized integration, compositor, transitions and mixed decoded 4K60 exports passed; the full 7,838 visual-quality audit was not rerun.

Published at https://pulsecanvas.si/download/ and https://pulsecanvas.si/downloads/PulseCanvas-Studio-1.0.3-11.dmg with matching source https://pulsecanvas.si/downloads/PulseCanvas-Creators-1.0.3-11-source.tar.gz and /appcast.xml. Website production deployment dpl_Bd583gRF7gCqZ6zZuR5ripan3q1u. Source archive is explicitly an uncommitted working-source snapshot; its 8,163 inputs match recorded hashes. Private signing keys/preferences/session data are excluded. No commit/push, App Store upload, distribution change for the Store configuration or local installation occurred. Detailed packaging/publication receipts: `.build/creators-release-1.0.3/build/direct-distribution/`.

Live page and actual prebuilt upload file hashes verified. Automated browser binary download check encountered save/multiple-download permission prompts and was not completed; consult the release receipt for final status. Do not claim that publication clears third-party preset/texture permissions.
