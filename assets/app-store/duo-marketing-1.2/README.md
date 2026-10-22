# iPhone Duo marketing screenshots — 1.2

The six campaign slides use real native app captures: music, Studio, visual style,
Radio, export and Completely free. Current captures retain the six Studio controls
in two aligned rows. The original untracked mobile-marketing-1.1.5 folder is preserved.

## October 22 refinement

Each feature has a different featured visualizer: Mercury Fold for full screen,
Plasma Bore for Studio, Aurora Fold for style, Orbit Loom behind Library, and
Lotus Resonance behind export. Radio shows its live selection (Windowpane Drizzle
on Duo and Veil Passage Coaster on iPad; iPhone uses Wind Tunnel to avoid
repeating Mercury Fold). The full bundled
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
PC_MARKETING_ACK_DIRECTORY to a host directory. Set PC_MARKETING_LEAD_ONLY=1 to
capture just the liquid opening and tunnel Studio
views, with PC_MARKETING_REFRESH_RADIO=1 to refresh iPhone Radio as well.
The capture host saves each stage
from simctl io screenshot before acknowledging it. Duo's active inner display is
--display=3. Unfold Duo with Device Hub’s Open button before launching the test;
a folded simulator has an inactive inner display. iPhone uses portrait; iPad and
Duo use landscape.

All captures, cropped details, PNG outputs, contact sheets and acknowledgments stay
outside Git:

`/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/closed-duo/`

Generate complete control crops before rendering:

```sh
python3 assets/app-store/shared/prepare-callouts.py '/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/closed-duo/raw'
PLAYWRIGHT=/Users/brad/Documents/GIT_SOURCE/jotley-site/node_modules/playwright/index.mjs \
node assets/app-store/duo-marketing-1.2/render.mjs \
  '/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/closed-duo/raw' '/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/closed-duo/duo'
```

The manifest records raw captures, derived control crops and rendered image hashes.
Final canvases: iPhone 1320×2868, iPad 2752×2064, Duo 2853×2007, opaque RGB PNG.
The numbered campaign images are followed by the all-device availability slide.
Placements are saved to the English (U.S.) 1.2 draft; this does not submit review.

The delivered opening and Studio replacements use JPEG quality 97 without
chroma subsampling. Lossless renders remain preserved. Other accepted screenshot
placements and their ordering are retained.

The Completely free slide now uses a native 1398×2034 closed-Duo Library capture,
fully visible in a portrait frame. Capture it with PC_MARKETING_DUO_CLOSED=1,
Duo set to Closed in Device Hub, portrait orientation and display 1. The same
scenario captures Ink Bloom in Studio for the Duo-specific availability slide.
Both are acknowledged before advancing. Other five Duo campaign slides retain
their existing pixels.
