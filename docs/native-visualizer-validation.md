# Native visualizer validation: combined catalog

2026-10-13. MacBook Pro, Apple M3 Max, 48 GB, macOS 27.0.1, Xcode 27.0.

The worktree catalog keeps IDs 0–199 and appends the main development catalog's existing 100 additions at IDs 200–299. Validation initially covered 287 offered designs and 13 reserved retired IDs. A concurrent final duplicate review then retired IDs 262 (Neon Needle → Violet Velocity, 270) and 277 (Velvet Wormhole → Golden Gyre, 259), leaving 285 offered designs and 15 reserved retired IDs. The earlier GPU checks cover that superset; the final development build and delivery exclude 262 and 277. No new designs were created in this integration. See `native-import-mapping.json` for the mapping between the unpublished development catalogs. User projects, soundtrack files and preferences were not migrated or rewritten.

**Owner-curated catalog (2026-10-13):** the owner's keeper review left **181 offered designs and 119 reserved retired IDs** (`docs/metal-keeper-selection.json`). On that catalog the full suite, excluding the long OpenGL preset audit, passes 30/30, including native expansion (181 active), Chaos, zoom, canvas coverage, encoder surface, audio sync, store edition and migration.

**Designs 300–369 (branch `new-claude-visualizers`, 2026-10-13):** seventy designs were appended after the review, for **251 offered designs**. Every new design passes the gallery checks at its default look: zero-Chaos isolation (exactly 0.000), music response (area at least 27%), beat, palette, wrap, zoom, coverage in 320x180 and 180x320, and 4K timing (at most 5.9 ms). All seventy also clear the integration music-response limits (attack alone, edges, music clock alone and each band alone), and none is 0.85 or more similar to an offered design except 352 vs 267, which were reviewed side by side and are distinct. The full suite, excluding the long OpenGL preset audit, passes 30/30 on the 251-design catalog. Thin-strip canvas meshes (15, 16, 17, 20) now shade with mesh normals, which removed an intermittent zero-Chaos and repeated-timestamp mismatch without changing their images.

## Defaults and music response

The same `VisualPreset.defaults(for:)` supplies the editor, Reset and Studio exports. Existing saved appearances take precedence. GPU checks confirm palette fidelity rather than relying only on palette indices.

| Default palette | Designs |
|---|---:|
| Blue Hour | 59 |
| Fernlight | 32 |
| Emberlight | 68 |
| Electric Candy | 82 |
| Ultraviolet | 44 |

Final default counts above exclude 262 and 277; the earlier 1,435-frame palette check covered all 287, including the subsequently retired designs.

All 27 designs listed as weak in the handoff now exceed its instantaneous music-response targets at default Chaos 0.6: median affected area increased from **6.0% to 54.3%**, the minimum is 38.3%, and minimum mean RGB response is 9.53/255. These measurements describe that subset, not the entire catalog. Band followers now attack in 18 ms and release in 95 ms. Roads and drives carry local travelling reflection waves; the older designs gain band-driven folds, crests, ring motion, chamber signals and flock deformation.

The 100 integrated designs use their separate common prelude so explicit clock motion in the worktree families is not applied twice. Their sharp attack pulse moves shapes; the dedicated regression measures a minimum RGB displacement of 7.78/255 and edge displacement of 1.85/255. Every frequency band and integrated music clock is connected. Over 240 actual soundtrack frames, six representative integrated designs respond 7.19–23.55/255 on measured attacks versus 0.14–1.11 between attacks, with strobe disabled. These are source-time comparisons at unchanged default Chaos, not a whole-frame flash test.

## Automated checks

| Check | Result and scope |
|---|---|
| Native expansion | PASS: all 287 cover at least 14/16 cells in five canvas shapes at three actual song positions. All 41,041 pairs differ using the same palette; the closest pair differs 14.1/255. The 269 procedural designs export and decode across wide, phone and square: 8,070 frames each, soundtrack present, no missing or black frames. A 120-frame 4K60 multi-section export also decodes |
| Audio sync | PASS: attacks visibly change all 287 with strobe disabled; 1,435 GPU palette outputs retain their blue/warm/green character |
| Chaos | PASS: all 287 are pixel-identical to silence at zero Chaos across wide/portrait and three zoom speeds; procedural motion continues |
| Encoder surfaces | PASS: all 287 offscreen and encoder-surface frames are byte-identical, including blur and music response |
| Canvas coverage | PASS: 2,296 coverage checks and 574 motion/determinism checks; minimum spans 95.3% × 96.5% |
| Migration | PASS: native, external and retired identities, shared looks, projects, timelines and favorites remain readable |
| Offline renderer | PASS: 1,722 deterministic offline checks |
| Organic pulse | PASS: local geometry response cannot be explained by global scale, translation or brightness |
| Zoom and store edition | PASS: all 287, zero-zoom framing, tunnel continuity, backwards seeks, music response, no projectM/OpenGL imports in the store binary |
| Renderer, blur, spatial, original geometry, audio, rhythm, strobe, Studio, compact layout, preset strip, social export, export feedback, engagement | PASS. A spatial compile overlapped the display-name fix and was rerun successfully after sources stopped changing |
| Dedicated music response | PASS: the integrated 100 and actual soundtrack attack/quiet comparisons above |
| Preset provenance | PASS: nine existing provenance tests |
| Optional OpenGL compositor, pack and transitions | PASS. Pack check loaded all 7,838 existing presets with zero load failures; this does not establish visual quality or licensing clearance |
| Optional OpenGL integration | Unresolved failure in the separate direct-edition test. Initial integration uncovered three display-name collisions and an obsolete unique-icon assertion; these were corrected. Its optimized run still traps without an assertion message; a diagnostic unoptimized build passes library, migration, actual GPU rendering, portrait export and all five 4K transition sections. This nondeterministic OpenGL test remains unresolved; no engine or preset assets enter the Metal development app |
| Full OpenGL preset playback-quality audit | Not completed in this continuation: an older audit was already running in the same worktree, so the duplicate run was stopped. Do not report this as passed |
| Unsigned Xcode development build | BUILD SUCCEEDED. The 285-design rebuild and ZIP were verified against the source snapshot at packaging time: 300 reserved IDs, 285 active designs, 21 hashed Metal resources, matching soundtrack, no `.milk` presets or projectM/OpenGL-linked binary |
| Release signing, notarization, App Store submission | Not run; no release or distribution changes made |

Detailed logs and receipts are under `.build/continuation/`; the initial completed suite results were preserved as `suite-before-audit.txt`. Remaining tests use isolated log directories to avoid writing into another audit's files.

## Continuity and visual review

Ion Cathedral passed audit, wrap, zoom, attack, palette, wide/phone coverage and timing checks. The 27 strengthened designs passed the same targeted visual checks; Prismatic Dunes needed a palette correction, which passed on rerun. A final 20-second continuity sample at zero Chaos and Zoom speed 3 found no isolated jump in 15 representative original, worktree and integrated designs, including Octagon Vault, Ink Cyclone and Ion Cathedral.

Default-look contact sheets now contain every active design in wide, phone and square. `motion-strips.jpg` contains six instants over four seconds for 16 representative designs from both sets, driven by the real soundtrack. Review shows local surface and object motion rather than a uniform frame pump. Automated pairwise pixel distinction is useful evidence, not a guarantee of perceptual uniqueness in every possible setting.

## Timing limits

The full suite's 1080p/4K timing overlapped another OpenGL audit and the gallery export. Those numbers include GPU readback and competing work, so they are not quiet GPU benchmarks or a real-time frame-rate guarantee. The standalone gallery timing before integration measured Gyroscopic Garden at 5.22 ms after a conservative ring-bound early-out (12.40 ms before), and Ion Cathedral at 5.18 ms at 4K. The eight-millisecond design target is **not met by every effect**; measured examples include Prismatic Dunes 30.24 ms, Pigment Burst 10.83 ms and Fire Dance 10.25 ms. Export keeps every requested frame even when rendering is slower than real time.

The full 287-section 4K60 raw gallery contains 861 seconds and exported in 634.5 seconds under concurrent validation load. Final labeled-video validation is recorded in the delivery receipt after the label pass finishes.

## Decoded gallery color verification

Exact midpoint frames from all 285 final gallery sections were decoded from the actual exported video, not generated separately for a contact sheet. Pixel hue analysis found 63 green, 58 blue, 10 cyan, 64 orange/yellow, 20 red and 70 violet/magenta sections. Violet remains a deliberate option, not the default for every design. The final gallery excludes sections 262 and 277, alternates palettes after that removal, and uses lossless video/audio track assembly to retain the rendered pixels. All three final metadata files match the exact 285 active IDs and retain default Chaos above zero. See `native-visualizers/decoded-video-color-preview.jpg` and the complete decoded contact sheet.

## Delivery and concurrent source changes

The final `PulseCanvas-native-visualizers-{4k60,phone,square}.mp4` galleries each contain the exact 285 active IDs, three seconds per design, at default Chaos and varied default palettes. The 4K60 video decodes all 51,300 frames; phone and square each decode all 25,650 frames. Soundtrack, cadence and nonblack interiors pass in all three. The decoded contact sheet contains every final section. Receipts and movie hashes are in `.build/continuation/final-receipt.json`.

### Complete similarity review (after packaging)

- **Coverage:** every pair scoring ≥ 0.85 on the structural-similarity check was reviewed: 116 pairs involving 35 designs. They were compared visually in their default looks, and the radial web and tiled-motif families also side by side in one palette at two song times.
- **Retired as near-copies:** 245 Saffron Spindle (→ 249 Fuchsia Furnace) and 259 Golden Gyre (→ 270 Violet Velocity). 277 Velvet Wormhole now resolves to 270.
- **Kept:** all other flagged pairs are different designs that share fine texture.
- **Catalog:** 283 offered designs and 17 reserved IDs. On this catalog, native expansion (39,903 pairs distinct; closest 14.1/255), migration, chaos, store edition, audio sync and Studio all pass.

### Shader edits after packaging

These edits are newer than the packaged gallery and ZIP; rebuild both before shipping.

**Changes.** All are Chaos-scaled. Measurements use `musiccheck` (share of pixels the instantaneous music changes by more than 12/255, at default look).

| Design | Area before → after | What changed |
|---|---|---|
| 46 Crystal Orchard | 13.9 → 39.5% | Per-cluster band glow; the glide uses the music clock |
| 58 Kelp Cathedral | 14.8 → 50.5% | Per-frond band glow with pulses climbing the stalks on the music clock; sway and layer approach use the clock. Its blocky noise-based marine snow is replaced with soft round motes |
| 59 Solar Filigree | 15.2 → 36.9% | Granules churn on the clock and swell per band; streamers, rim and spicules respond |
| 96 Glacier Rift | 13.6 → 66.7% | Flight uses the clock; strata glow per region band; light wave along the walls |
| 97 Firefly Meadow | 14.9 → 19.4% | Blade-tip shimmer per band; layers approach on the clock; stronger firefly response |
| 85 Ocean Swell | 17.8 → 18.6% | Glide uses the clock; crests glow on the low-mids in rolling bands |
| 4 Bead Surge | 15.7 → 45.2% | Per-bead swell and glow in `SpatialVisuals.metal` |
| 12 Pearl Terrain | 4.8 → 43.7% | Per-pearl bounce and glow in `SpatialVisuals.metal` |
| 26 Prism Rain | 13.0 → 60.9% | Per-prism pump and glow in `SpatialVisuals.metal` |
| 27 Monolith Rush | 13.1 → 45.4% | Per-tower height pump and glow in `SpatialVisuals.metal` |
| 29 Tidal Glass | 4.7 → 58.7% | Level-driven heave and crest light in `SpatialVisuals.metal` |

**Duplicates and music, whole catalog.** Pixel distinctness passes on the final 285 (40,470 pairs; closest 14.1/255). No design is below 12% area. Luminous Nautilus (17.0%) and Indigo Infinity (17.3%) are the only ones under 18%, and both move strongly with the music clock.

**Supplemental reel.** A labeled 1080p30 reel of these 11 designs with the real soundtrack is at `.build/deliverables/PulseCanvas-music-pass-supplement-1080p-labeled.mp4` (44 s, 4 s per design).

**Checks on the changed designs.** Audit, wrap, zoom, attack, palette and wide/phone coverage pass. `test-spatial-visuals` and `test-organic-pulse` pass.

**4K timing** (shared GPU):
- Crystal Orchard: 28–29 ms (26.8 ms before these edits). A conservative bounding early-out is pixel-identical but saved little.
- Glacier Rift: 17 ms.

**Intermittent determinism failure.** On a fresh full-suite snapshot, `test-store-edition` failed once ("Zero Chaos leaked music … Lotus Resonance"), and `test-chaos` once on a re-run; both pass on other runs.
- A probe reproduces it without any music. After heavy raymarched frames, the first Lotus Resonance frame can differ from an identical re-render by ±1/255 at scattered pixels.
- Removing the screen-derivative normal in `canvasFragment` eliminates it, so the cause is derivative shading on Lotus's thin ring strips, not audio leaking at zero Chaos.
- Fix options are recorded in `HANDOFF-native-visualizers.md`.

After this snapshot was rendered and packaged, another process continued editing NativeNature and NativeFlow in the shared worktree. Those edits are preserved. The verified gallery and development ZIP should not be represented as validating or including these newest ongoing shader edits; a finished handoff is needed before another final rebuild/export. No signing, installation, commit, push or release was performed.

## Red-label curation and surface fixes — 2026-10-13

The current catalog offers 181 red-tagged keepers. All 300 permanent slots remain, with 119 withdrawn IDs redirected to offered styles. The red-label evidence and deleted implementation functions are recorded in `metal-keeper-selection.json`. Review files and their tags remain intact. The 285-style results above are historical validation of the earlier superset.

The curated native expansion check passes all 181 styles, every canvas shape, all 16,290 pair comparisons, Studio switching and decoded wide/phone/square exports through its 164 procedural styles (4,920 frames each), plus a 120-frame 4K60 export. Migration, saved settings and favorites pass against the approved red-label selection.

The broken surfaces in the prior review were present in unencoded GPU frames. Pearl Terrain and Prism Rain now use neighboring-object unions and exact sphere/octahedron ray intersections with bounded cell traversal. This removes clipped faces and iterative surface misses. Timing at 1080p after the exact intersections measured 3.35 ms for Pearl Terrain and 7.69 ms for Prism Rain; measurements include GPU readback and do not promise real-time 4K60. Mandel Bloom uses a continuously bending domain and an integer power, preserving its angular seam and poles while the actual folds respond to bands and attacks. All three pass zero-Chaos isolation, motion continuity, palette, beat and music checks.

The three revised GPU outputs match the encoder’s IOSurface byte for byte over 60 consecutive frames each, including blur, strobe and music. Their separate 12-second 4K60 MP4s each decode all 720 frames with a soundtrack and nonblack interiors. A passthrough cut initially failed its frame-count check; the delivered revisions were encoded as complete standalone clips and passed.

Ferrofluid Crown was unmarked and is withdrawn. Its analytic-slope, continuous height-field rewrite is preserved only as a separate prototype; the prototype MP4 passes all 720 frames at 1080p60. It does not ship in the curated app.

The unsigned 181-style Xcode development build succeeds and its actual resource catalog, shader hashes and soundtrack match the source. No release signing, installation, commit, push or App Store upload was performed. The earlier optional OpenGL integration failure remains outside this native change’s validation.
