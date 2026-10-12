# App code audit — 1.0.1 (4)

Audited the 24 Swift app files before cleanup, Metal entry points and bindings, resource build inputs, both app targets, and the engineering harnesses. Reference searches were checked against actual callers, dynamic shader names, framework callbacks and saved-project decoding. Third-party engine source and preset equations are separate runtime dependencies; the preset library remains intact.

## Removed from the app

- The unused 2,650-line point-catalog geometry module. Numerical fixtures still exercise it from `scripts/reference/PointGeometry.swift`; neither app target compiles it.
- Five scalar formulas absent from every scene pool. The app retains all 74 reachable formulas. The five numerical fixtures are in `scripts/reference/FormulaGeometry.swift`.
- Unused geometry defaults, scene presentation metadata, the star-group generator and its unused integer sampler.
- Retired preview frame-capture callback, readback buffer, capture flags and completion wrapper. MP4 export still uses its independent offscreen renderer and shared GPU surfaces. Live-preview validation no longer requires production capture hooks.
- A duplicate galaxy pipeline allocation and 22 unused AIR shader modules, including the retired edge-blur variants. Source-audit references remain in `scripts/reference/shaders`, outside app resources. The runtime library contains 13 active functions; pipeline construction still rejects missing required functions by name.
- The unused preset-import writer and name generator. Existing imported-pack metadata, texture resolution, favorites, stable identities and project migration remain readable; the import action was already absent from the UI.
- The test-only spectrum alias and redundant band wrapper. Tests now use the actual analyzer frame API.

The remaining single-reference declarations are SwiftUI entry points or framework lifecycle callbacks. Codable fields and migrations were retained for existing projects. No scene IDs, palette definitions, user preferences, soundtrack assets or presets were removed.

## Verification

- 372 GPU frame hashes match build 3 exactly: all 31 native visualizers, wide/portrait, three timestamps, Chaos 0/0.8, content blur enabled.
- 62 live-preview/error and offscreen pixel checks pass with blur off/on.
- Geometry, family and 775 point-catalog numerical fixtures pass.
- Chaos and local organic-deformation regressions pass, including zero-Chaos music/silence equivalence with ongoing motion.
- Studio persistence, old-project migration, legacy imported packs, favorites, bar edits and randomization pass.
- Audio load, FFT, playback, pause, seek, loops and default soundtrack checks pass.
- Social export, cancellation/replacement, decoded native/ProjectM transitions and 4K/60 MP4 checks pass.
- SwiftPM release and signed sandboxed Xcode builds pass. Bundle validation confirms version/build, arm64, sandbox entitlements, signing, notices, 7,838 presets and only 13 active shader-source resources.
- The sandboxed app's Save video action opens a destination picker before rendering; cancelling leaves the soundtrack ready. Saved-video playback actions remain absent.

Engineering logs and before/after GPU hashes: `work/unused-code-audit/` (local, ignored). TestFlight delivery is documented separately after Apple's processing completes. Public App Review and the existing rights/source-publication gates are separate.
