# iPhone Duo marketing screenshots — 1.2

Six landscape App Store slides, using the approved iPhone/iPad campaign's HTML/CSS
layout, Avenir Next typography, light background, accent colors, badges and real
UI callouts. The original untracked `mobile-marketing-1.1.5` artwork is preserved.

Order: music / 300+ Metal visualizers; Studio; visual style; Radio; MP4 / 4K60;
completely free. Every final canvas is 2853 × 2007, opaque RGB PNG. Wide inner
captures appear in minimal device frames. These are
presentation frames, not a claim to reproduce the physical Duo hardware.

## Real app sources

Captures are from the native mobile 1.2 (8) app on the owned Duo inner-display
simulator. Studio uses the included soundtrack; Radio uses the real catalog.
No QA fixtures or generated app UI appear in the artwork. Enlarged controls are
crops of these same captures; screen images retain their original aspect ratios.

`testCaptureCurrentMarketingLayout` captures Studio, full screen, style, Radio,
Library and the Export sheet with 4K and 60 fps selected. It passed on
October 21, 2026. Active-display
`simctl io … screenshot --display=…` capture is required: XCTest's screenshot
attachment can select Duo's inactive display.

Raw source folder (outside Git):
`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/raw/`

Artwork, contact sheet, source/output hashes and App Store upload evidence:
`/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/duo/`

## Rebuild

```sh
PLAYWRIGHT=/Users/brad/Documents/GIT_SOURCE/jotley-site/node_modules/playwright/index.mjs \
  node assets/app-store/duo-marketing-1.2/render.mjs \
  '/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/raw' \
  '/Volumes/Music/Codex Media/PulseCanvas Studio/App Store/1.2/Layout-refresh/duo'
```

The renderer checks copy bounds and image decoding, renders six full-resolution
slides plus a contact sheet, and writes SHA-256 hashes for every capture used and
every output. PNG dimensions and RGB mode are verified separately before upload.

These slides refresh the English iPhone Duo group. Matching iPhone and iPad
refreshes use `../mobile-marketing-1.2/`. Previous images remain recoverable in
Apple's Asset Library. Header and search assets are preserved. This does not
submit a release.
