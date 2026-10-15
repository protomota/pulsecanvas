> Historical development snapshot. The completed main integration now has 181 reviewed Metal effects with separate Store and Creators builds; see [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md). The active new-claude-visualizers worktree is excluded.

# Native Metal expansion: historical review snapshot

**Superseded by the integrated main-checkout development snapshot.** The reviewed fixes and newer source-time audio pipeline have been integrated, with further Harmonic Trace, Ring Shepherds and Gyroscopic Garden fixes. See [NATIVE-DEVELOPMENT.md](NATIVE-DEVELOPMENT.md) for current verification. The results below describe the earlier isolated snapshot and its failures; they are retained as historical evidence.


The primary checkout retains its existing 60-effect work. Another agent is developing 100 effects in `.claude/worktrees/native-visualizers-100`; that worktree is still changing. Its edits and the installed application have been preserved.

An isolated snapshot at `.build/native100-review` now builds an unsigned development app with 100 native effects. It uses the existing version 1.0.2 (10) for testing only; it has not been installed, signed, uploaded or released. The snapshot is older than the other worktree's latest audio-analysis and default-profile changes. It must be reconciled before integration.

## Verified snapshot fixes

- Offline native frames no longer inherit audio smoothing from earlier rendered frames. All 69 added designs reproduced identical frames after different audio histories in landscape and portrait. The newer external worktree has since replaced renderer smoothing with source-time envelopes; prefer that implementation and revalidate it rather than applying the obsolete smoothing patch blindly.
- Setting live Chaos to zero clears the retained music-clock offset while procedural time and configured zoom continue. This defect was also reproduced against the newer external `NativeMotion`; `zero-chaos-clock-latest.patch` demonstrates the fix without editing that worktree.
- Original surface lighting uses explicit triangle normals. A 7,200-frame test passed exact music/silence/repeated-silence comparisons.
- Arc Foundry and Fractal Canopy receive the existing continuous zoom pass because their internal travel did not meaningfully zoom the composition. All 100 designs passed zero/low/high zoom-control checks; the three established tunnels also passed 3,240 playback-cadence transitions.
- Ribbon Foundry receives more ambient illumination in portrait. Murmuration has a wind-lit foreground. Firework Garden has a distant star field between launches. Full-canvas coverage passed 770 checks and 200 motion/seek checks across 100 effects.
- Arc Foundry uses smooth procedural source illumination and fades in recycled sparks. Its sampled zero-Chaos peak/median frame-change ratio fell from 18.4 to 1.3; audio response remains visible.
- Neon Calligraphy bounds each stroke's visible region and tests only nearby segments. Completed 4K frames measured 21.27 ms before and 9.41 ms after in ten-frame samples. At 640×360 the sampled image changed by at most one channel level, with mean RGB difference 0.00152. This is a bounded observation, not a universal performance claim.

Focused patches are in `.build/native100-review/patches`. The empty obsolete store-input patch was removed; the newer external test script already includes `NativeEffects.swift`.

## Verification and artifacts

The snapshot passed:

- Store catalog/defaults/identity migration checks for 100 effects, preserving legacy external index 31.
- All 100 audio-response, zero-Chaos, deterministic-seek and continuing procedural-motion checks; zero-Chaos coverage includes landscape/portrait and three zoom speeds.
- 600 offline GPU checks against the actual generated app's resources.
- Byte-identical GPU encoder-surface output for all 100 effects, including content blur, audio and strobe over consecutive frames.
- An unsigned Release Xcode build. The actual bundle has contiguous `native:0`–`native:99` IDs, source-matched shader hashes and demo audio, no `.milk` files, and no projectM/OpenGL/Sparkle dependencies.

The wide export decoded all 4,140 frames at 1280×720/30 fps with soundtrack and 69 scene comparisons. Its original strict RGB tolerance failed for Mandel Bloom: 12.3589 against a limit of 12. The expected and decoded full-resolution frame show matching structure with compression loss in fine detail. The diagnostic comparison reports that error; it does not supersede the failed strict test. The subsequent portrait and 4K export stages were not run by that test.

Receipt with source, bundle, patch and log hashes:
`.build/native100-review/.build/validation/review100-receipt.json`

Visual artifacts:

- Landscape and portrait contact sheets: `.build/native100-review/.build/contact-wide-all.png` and `contact-phone-all.png`.
- Twelve-second motion sample of Ferrofluid Crown, Chrome Metaballs and Mandel Bloom: `.build/native100-review/.build/motion-review/liquid-review.mp4`.
- Full wide export: `.build/native100-review/.build/native-expansion/native-expansion-wide.mp4`.

## Remaining work

Reconcile the focused fixes with the external worktree's newer audio pipeline and profiles, then integrate without losing the primary checkout's surface-lighting and compatibility work. Review actual motion across all 100 designs, optimize slower 4K effects, finish portrait/4K export checks, and refresh package/source-archive verification after integration. No full-catalog motion-quality claim, release approval or licensing clearance is implied by this review.
