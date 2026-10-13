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
