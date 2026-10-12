# Point geometry

The point generator has 79 scalar formulas, including trigonometric, exponential, rounded, radial, and singular surfaces. Each formula preserves operation order, binary constants, and floating-point classification. The native rounding instruction `frintp` is represented by `ceil`, rather than integer truncation.

The catalog begins at address `0x100a95fc0`; formula entry points span `0x100403d10` through `0x100404f24`. Address-based comparison tooling verifies the expected input hash before executing those instructions.

The grid builder at `0x100405944` iterates x then y over the exclusive ranges `[-240, 240)` with a step of 4. For `adjust = 20`, points are `(adjust * 1.2 * x, adjust * 1.2 * y, adjust * formula(x, y))`. The result contains 14,400 points. Singular NaN and infinite values remain classified consistently; the vertex shader rejects nonfinite positions.

The morph at `0x100408248` blends two grids with weights `(length - count) / length` and `count / length`. The renderer traverses scene-specific formula pools deterministically from absolute time, making scrubbing and export reproducible. Morph length 110 follows the effective speed profile; the underlying initial parameter default is 100.

| Scene | Pool size | Available formulas | Camera scale | Halo size |
| --- | ---: | ---: | ---: | ---: |
| Lumen Veil | 46 | 44 | 1 | 3 |
| Prism Wake | 23 | 22 | 1.3 | 2.3 |
| Pulse Well | 17 | 17 | 1.3 | 3 |

Pool filtering excludes IDs absent from the catalog. Projection uses a 56-degree FOV, near plane 1, far plane 1500, camera distance 120, model scale with float bits `0x3c9374bc`, and a fixed 90-degree z rotation. Point size uses `drawableHeight / 0.8284271`.

`test-geometry.sh` checks grid ordering, counts, formula examples, pool filtering, morph arithmetic, defaults, and input guards. Independent ARM64 instruction execution matched compiled Swift at five coordinate pairs per formula: 395 comparisons at relative tolerance `1e-13`, including matching NaN/Inf classifications. These samples establish numerical agreement for the tested inputs, not a proof of every possible input.
