# Mobile marketing screenshots — current 1.2 layout

Six slides each for iPhone (1320×2868) and iPad (2752×2064). The approved
1.1.5 marketing design and copy are retained; the real app captures and enlarged
detail crops now show 1.2 (8), including visualizer controls above the preview,
playback/scene actions below, and the bottom timeline. The original untracked
1.1.5 artwork folder is preserved separately.

Captures, rendered PNGs, contact sheets and upload receipts stay outside Git:

`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/`

`raw/` contains real simulator screenshots from the normal app and bundled
soundtrack/live Radio, without QA fixture content. The UI capture scenario is
`testCaptureCurrentMarketingLayout` in `mobile/UITests/PulseCanvasMobileUITests.swift`.
It prints `PC_CURRENT_CAPTURE <stage>` and holds each view for seven seconds so
the host can capture the active native framebuffer with `simctl io screenshot`.
Use the active display's native resolution; an inactive Duo display can contain
stale content and must not be used. Capture to `/tmp` first, then copy to Music
if Simulator is denied direct access to the volume.

Required names: `iphone-{studio,fullscreen,style,radio,library,export}.png` and
`ipad-{studio,fullscreen,style,radio,library,export}.png`. Use portrait iPhone and
landscape 13-inch iPad. `TEST_RUNNER_PC_MARKETING_ORIENTATION=portrait` or
`landscape` selects the pose for the capture test.

Rebuild from the repository root:

```sh
PLAYWRIGHT=/Users/brad/Documents/GIT_SOURCE/jotley-site/node_modules/playwright/index.mjs \
node assets/app-store/mobile-marketing-1.2/render.mjs \
  '/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/raw' \
  '/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/mobile'
```

The renderer writes `release/en-US/`, two contact sheets, and a SHA-256 manifest.
`manifest.json` here records the delivered source and output hashes. Upload the
numbered slides in order: music, Studio, style, Radio, export, free. Review all
slides visually and verify opaque RGB, dimensions, file sizes, server processing
states and placement order. Save only; review submission is a separate action.
