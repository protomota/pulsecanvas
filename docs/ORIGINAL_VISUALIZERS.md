# PulseCanvas visualizer designs

Seven new designs generate geometry directly from the soundtrack spectrum and project timestamp. Preview, scrubbing and offline export use the same pure generation functions. Arc Spray uses a fixed integer hash and timestamp-derived particle ages; rendering never depends on a mutable random generator or a previous frame.

| Scene ID | Design | Geometry | Music response |
| --- | --- | --- | --- |
| 15 | Petal Echo | Eleven concentric twelve-petal rosettes | Angle-local bands swell petal radii and widths; bass breathes the full mandala. |
| 16 | Orbit Loom | Seven tubular rings tilted around different axes | Local frequencies thicken and expand the arcs; bass expands each orbit. |
| 17 | Silk Current | Eight twisting silk ribbons spanning depth | Frequency position along each strip changes crest height and strip width. |
| 18 | Double Twist | Four tall corkscrew strands | Bass spreads strands; height-local frequencies add radius and transverse ripple. |
| 19 | Arc Spray | Deterministic ballistic spray | Each particle samples a different band to control launch height and lateral spread. |
| 20 | Signal Tiles | A field of isolated luminous tiles | Frequencies lift tile columns, while bass drives travelling diagonal pulses. |
| 21 | Resonant Shell | A closed flower with five major lobes | Local bands deform petals and fine ridges; bass breathes the whole surface. |

All designs also respond through color luminance. Their geometry is centered around the origin, with typical default extents inside ±12 world units. Camera fitting is the renderer's responsibility. Triangle designs provide per-vertex color and UVs. The helix and fountain provide point vertices and recommended point size; the renderer chooses how to shade the points.

`OriginalGeometry.make(scene:time:spectrum:intensity:palette:)` returns vertices, triangle indices (empty for points), primitive type and point size. Invalid spectra are sanitized; an unknown scene returns an empty mesh. Animation advances from the absolute timestamp, so exporting a selected range or revisiting a frame does not require simulating the earlier timeline.

`./scripts/test-original-geometry.sh` compiles with Swift 6 and checks all seven designs for deterministic repeat frames, animation progress, finite positions and colors, valid topology, actual audio displacement and color response, and distinct response to low versus high frequencies. These checks passed on October 10, 2026. They verify geometry behavior; rendered appearance is checked separately by the Metal renderer tests.

The renderer expands these local geometries into animated fields that extend beyond the canvas. This repeating layout, moving perspective framing, and palette-preserving directional surface lighting are separate from the pure geometry generators.
