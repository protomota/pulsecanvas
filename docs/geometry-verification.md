# Native geometry coverage

The renderer builds its shader library from 13 active textual Apple AIR LLVM modules. The other 22 historical modules are under `scripts/reference/shaders` for source auditing and are not bundled. The CPU kernels below were translated from ARM64 reference instructions with direct register/instruction inspection. Swift position output is checked against ARM64 instruction emulation, with imported trigonometric routines represented by system math operations.

| Kernel | Native address | Verified behavior | Integrated use |
|---|---|---|---|
| Formula grid | `0x100403d10`…`0x100404f24`, catalog `0x100a95fc0` | 79 formulas, 120 × 120 grid, native pools, integer pingpong morph, native projection/model scale | First three point scenes |
| Shared textured tunnel | `0x1003abf44` | Early-ring radius ramp, sinusoidal radius, circular path offset, ring depth, conditional XY exchange | Textured tunnel and fractal families |
| Cyborg profiles | `0x1003a25a8`, table `0x100a94920`, collector `0x1003a1f58` | Eight exact profile tuples, modes 5/11, sine/tangent radius clamp, native axes/scaling | Contour Flux |
| Point catalog | `0x1003a8eb0` | 66 case IDs, XYZ expressions and inout integer phase counters | Constellation and cosmic host schedules |
| Star catalog | `0x1003a0adc` | 63 case IDs, native scalar XYZ expressions | Star-flight host schedule |
| Cloud catalog | `0x1003a86b8` | 26 case IDs, native scalar XYZ expressions | Interstellar host schedule |
| Star-group randomization | `0x1003af6dc` | 31 groups, first/last 6 share configuration, bounded integer draws divided by 10, compact center mask, depth spacing | Catalog fixtures; Scatter Flight uses an authored depth field |
| Crystal ring mesh | `0x1003bc300` | Tangent/sine radius, radius floor, double XY clamp, squared-adjust depth | Facet Flow |
| Crystal cone mesh | `0x1003c3a50` | Single-precision ring radius, native sincosf angle, exchanged XY scales and depth | Glass Current |
| Galaxy spiral | `0x1003db6e8` | 1050 double-precision samples, two-degree increment, radial accumulator increment `.00015225`, factor `1090`; depth/scattering wrapper `0x1003db818` preserves first 151 XY scatter and tail depth-outlier probabilities | Spiral Tide |

The first three grid formulas have 395 instruction-emulation comparisons covering all 79 formulas at five coordinates, including origin and negative coordinates. The four additional mesh kernels have 26 comparisons across zero, ramp boundaries, large ring indices and spiral endpoints. Cyborg has 40 native kernel/collector comparisons covering all eight profiles. The 155 point-catalog case IDs have 775 comparisons across five input sets, including negative coordinates and integer phase counters. Single-precision position tolerance is relative `1e-6`; the formula checks use `1e-13`. Native NaN/Infinity classifications are retained for the formula grid.

Run `scripts/test-geometry.sh`, `scripts/test-family-geometry.sh`, `scripts/test-point-geometry.sh`, `scripts/test-renderer.sh`, and `scripts/test-offline-renderer.sh`. The family fixture file contains instruction-emulation output. `scripts/verify-family-native.py` can reproduce comparisons with an explicitly supplied ARM64 Mach-O and the Swift TSV output; it requires Python Unicorn. `scripts/verify-point-native.py` similarly verifies all 775 point-case fixtures against an explicitly supplied ARM64 Mach-O. No native executable or compiled vendor shader library is a build input.

## Verification scope

Scalar position verification covers the geometry kernels; host scene composition has separate validation. Textured mesh indices, UV layouts, camera travel, selected mesh windows, palette artwork and texture assets in the host renderer remain reconstruction choices. Verified wrapper defaults include: shared tunnel total 24000/20 segments, radius base 2.5, modulation .5, adjust 3; nebula ride radius 12, wavelength 14, depth factor 4, inner radius 3; fractal inner radius 2 and wavelength 80. Other mesh profile defaults and audio modulation are host choices, and the renderer marks those transformations in source comments.

The cosmic-point and constellation modes evaluate native catalog expressions. Scatter Flight uses an authored deterministic depth field of sphere sprites. Their host group scheduling, normalization, palette, fitted scale and camera are reconstruction choices. Native star-group randomization retains bounded distributions and shared groups, while a deterministic PRNG replaces OS randomness. The Galaxy wrapper retains native random-depth span arithmetic, first 151 planar jitter and `.25/.5/.75` outlier probabilities in the tail; the selected span and fitted viewport transform are host choices.

The three point kernels collectively cover 155 native case IDs (including aliases/default branches), with exact expression order. Source math is not inferred from scene labels. Some public preset labels share kernels and assets; the full native preset-to-controller association for the cosmic and lotus aliases has not been proven, so host catalog/family selection for these aliases remains explicit reconstruction. Native controllers, texture artwork and all original preset/state scheduling are outside this scalar verification scope.

Mandala, Orbit Loom, Silk Current, Double Twist, Arc Spray, Signal Tiles and Resonant Shell are original procedural modes in `OriginalGeometry.swift`. Their geometry responds to the supplied spectrum and is deterministic at a given timestamp. The fullscreen white flash is a separate original shader composed after radial blur; it uses a separate library from the 13 active visual functions.

Preview and offline exports share frame encoding and absolute soundtrack time. Shape selection for soundtrack seeks is a deterministic traversal of the configured scene pool rather than native randomness. This preserves morph arithmetic while producing reproducible seeks and exports. Offline output uses shared BGRA pixels and waits for GPU completion.


## Visual and GPU validation

All 22 modes pass 66 Metal validation checks (base, radial blur and wireframe). Offline checks cover 132 cases: repeated-timestamp byte equality, full-frame white flash after blur and low-band rejection, at landscape/portrait output sizes. Additional portrait captures at 236 × 420 were visually inspected with the default point preset and zoom 2. Ball structures are centered; sphere sprites have an opaque shaded core with a soft edge, and point modes use depth-sorted alpha-over blending to preserve color under dense overlap. Their point sizes and camera fitting are host presentation choices.

Runtime cleanup in 1.0.1: point-catalog kernels and five unused scalar formulas are verification references under `scripts/reference`, excluded from SwiftPM and Xcode app targets. The older numerical results below document the full catalog.
