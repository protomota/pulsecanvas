# Creative Metal studies

Two standalone, texture-free visual experiments for evaluating future native effects:

- **Violet Undertow:** two interlaced spiral fields, a drifting origin and travelling
  beat ripples that deform individual strands, with violet/rose highlights.
- **Aurora Weave:** nine luminous wave sheets with different depth/phase, teal/lime
  colors and local beat bends rather than a global screen-scale pulse.

`Creative.metal` uses newly authored procedural fields, line shading and controlled
framebuffer history. The only textures are the renderer's own generated framebuffers;
no preset texture pack or other image assets are loaded. The implementation does not
use projectM code or translate the earlier source-formula study. General visual ideas
are the reference; these are not pixel-equivalent ports of named presets.

These experiments are excluded from PulseCanvas's shipping builds, preserving the
31-effect Store count. They are evaluated separately before adding controls, live
soundtrack analysis or application integration. This is a technical description of
the implementation, not a blanket legal conclusion about other source-port work.

Run from the repository root on a Metal-capable Mac:

```sh
xcrun swiftc -O experiments/metal-studies/Render.swift -o .build/render-metal-studies
.build/render-metal-studies
```

The probe renders 240 GPU frames per style at 960×540 and 60 fps with a synthetic
rhythm. Output goes to `.build/metal-studies/creative-0.rgba` and `creative-1.rgba`.
For an MP4 preview:

```sh
ffmpeg -f rawvideo -pixel_format rgba -video_size 960x540 -framerate 60 \
  -i .build/metal-studies/creative-0.rgba -c:v libx264 -crf 16 -pix_fmt yuv420p \
  -movflags +faststart .build/metal-studies/violet-undertow.mp4
```

Validation on 2026-10-12: both Metal kernels compiled, all 480 GPU command buffers
completed, generated videos decoded, and frames showed visible moving content.
These checks do not establish live app performance, actual music synchronization or
4K export performance. The application regression checks remain separate.

## Backlit Rift

Backlit Rift is a separate volumetric smoke study. Metal ray-marches a
procedural density field, estimates light absorption at each sample, and
composites a copper filament behind the moving foreground smoke. Claude Fable
5.2 High directed the composition from
[Our storm-cloud reference](https://x.com/4KAestheticHQ/status/2124757450666774961).

The preview flies straight through a repeating three-dimensional cloud
corridor over eight seconds. The camera advances one full depth period at
constant speed, so nearby billows grow and sweep past the frame edges as
deeper clouds approach. Its synthetic 120 BPM beat brightens the filament and
adjacent cloud edges. Backlit Rift joined the shared app catalog in 1.3.3.
The preview renderer still works at both 16:9 and 9:16.

Run from the repository root on a Metal-capable Mac. Set `output` to your render
directory. The last two arguments select the frame count and starting frame in
the 480-frame loop.

```sh
output='/Volumes/Expand/Codex Media/PulseCanvas Studio/Backlit Rift'
mkdir -p "$output"
export TMPDIR="$output"
xcrun swiftc -O experiments/metal-studies/RenderSmoke.swift -o "$output/render-smoke"
set -o pipefail
"$output/render-smoke" 1280 720 480 0 | \
  ffmpeg -f rawvideo -pixel_format rgba -video_size 1280x720 -framerate 60 -i - \
  -vf 'scale=out_color_matrix=bt709:out_range=tv' -c:v libx264 -crf 17 \
  -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
  -movflags +faststart "$output/backlit-rift.mp4"
```

For a portrait preview, use `720 1280` in the renderer and `720x1280` in
FFmpeg. Both orientations rendered and decoded all 480 frames on an Apple
M3 Max. These are offline previews with a synthetic beat clock.

## Five additional studies

| Study | Renderer name | Motion and material |
| --- | --- | --- |
| Undersurface | `undersurface` | A view beneath a rippling water surface, with refraction, light shafts, and suspended silt |
| Mercury Fold | `mercury-fold` | A sculptural fold of liquid chrome and droplets under cool and amber reflections |
| Ember Front | `ember-front` | Forward flight through a curved front of copper sparks, with depth-dependent streaks |
| Anvil Flyover | `anvil-flyover` | Lateral flight above violet storm clouds with lit crests and internal flashes |
| Pigment Strata | `pigment-strata` | Cream, ochre, and wine-colored pigments rolling into vortices along their interfaces |

The six effects share `Sources/PulseCanvas/Resources/NativeExpansionAtmospheric.metal`
with the shipping app. The liquid studies use a procedural height field,
an implicit surface, or advected color. The app names the new liquid chrome
effect Mercury Ribbon to distinguish it from the earlier Mercury Fold preset.
The renderer accepts a study name after the start frame. The original
four-argument command still renders Backlit Rift, also available as
`backlit-rift`.

```sh
output='/Volumes/Expand/Codex Media/PulseCanvas Studio/Five Metal Studies'
mkdir -p "$output"
export TMPDIR="$output"
xcrun swiftc -O experiments/metal-studies/RenderSmoke.swift -o "$output/render-study"
set -o pipefail
for study in undersurface mercury-fold ember-front anvil-flyover pigment-strata; do
  "$output/render-study" 1280 720 480 0 "$study" | \
    ffmpeg -f rawvideo -pixel_format rgba -video_size 1280x720 -framerate 60 -i - \
    -vf 'scale=out_color_matrix=bt709:out_range=tv' -c:v libx264 -crf 17 \
    -pix_fmt yuv420p -colorspace bt709 -color_primaries bt709 -color_trc bt709 \
    -movflags +faststart "$output/$study.mp4" || break
done
```

The eight-second previews use a synthetic beat clock. In the app, the
shared renderer uses the soundtrack's measured attacks and the saved look.
