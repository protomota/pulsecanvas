# Mobile marketing screenshots — 1.2

The six campaign slides use real native app captures: music, Studio, visual style,
Radio, export and Completely free. Current captures retain the six Studio controls
in two aligned rows. The original untracked mobile-marketing-1.1.5 folder is preserved.

## October 22 refinement

Each feature has a different featured visualizer: Double Twist for full screen,
Pearl Terrain for Studio, Aurora Fold for style, Orbit Loom behind Library, and
Lotus Resonance behind export. Radio shows its live selection (Windowpane Drizzle
on Duo, Mercury Fold on iPhone, Veil Passage Coaster on iPad). The full bundled
2:54 soundtrack and live Radio are used, without shortened fixture content.

Completely free has only four pills: No subscriptions, No ads, No account and
No tracking. The GitHub label is removed. All Duo slides omit the decorative
outline that formed a triangle above the device.

Enlarged details use complete native control crops, with 48px padding for iPhone
and 64px for iPad/Duo on every side. The wrapper background matches the native
panel (#1f1924); it cannot expose an incomplete source-sheet background.
The renderers verify equal padding, image decoding and callout bounds.

## Capture and rebuild

Opt-in test: testCaptureVariedMarketingLayout in
mobile/UITests/PulseCanvasMobileUITests.swift. Set PC_MARKETING_VARIETY=1 and
PC_MARKETING_ACK_DIRECTORY to a host directory. The capture host saves each stage
from simctl io screenshot before acknowledging it. Duo's active inner display is
--display=3. iPhone uses portrait; iPad and Duo use landscape.

All captures, cropped details, PNG outputs, contact sheets and acknowledgments stay
outside Git:

`/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/variety/`

Generate complete control crops before rendering:

```sh
python3 assets/app-store/shared/prepare-callouts.py '/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/variety/raw'
PLAYWRIGHT=/Users/brad/Documents/GIT_SOURCE/jotley-site/node_modules/playwright/index.mjs \
node assets/app-store/mobile-marketing-1.2/render.mjs \
  '/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/variety/raw' '/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/variety/mobile'
```

The manifest records raw captures, derived control crops and rendered image hashes.
Final canvases: iPhone 1320×2868, iPad 2752×2064, Duo 2853×2007, opaque RGB PNG.
The uploaded iPad copies are JPEG quality 97 with chroma subsampling disabled;
Apple stalled on some PNG uploads. Lossless originals remain preserved.
The numbered campaign images are followed by the all-device availability slide.
Placements are saved to the English (U.S.) 1.2 draft; this does not submit review.
