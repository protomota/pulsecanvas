# iPhone and iPad App Store marketing screenshots (1.1.5)

Six designed slides per device, built the same way as the Jotley 2.1 set: an HTML/CSS layout composites real app captures into device frames with headlines, then Playwright renders each slide to an opaque PNG.

- iPhone 6.9": 1320 × 2868 portrait — `release/en-US/iphone-0N-*.png`
- iPad 13": 2752 × 2064 landscape — `release/en-US/ipad-0N-*.png`

Order: music (300+ Metal visualizers), Studio, Visual style, Radio, Export (4K60), Completely free. Copy and per-slide accent colors follow the Mac App Store slides (`../native-marketing-1.0.3-13/`), on a light background.

## Sources

Every screen in `sources/` is an unmodified capture of the current mobile build (main at 8d6da7b) running in the iOS 26/27 simulator on iPhone 17 Pro Max and iPad Pro 13-inch (M5), status bar overridden to 9:41. Captures came from a temporary XCUITest (not committed) that played Studio, opened full screen, Visual style, the visualizer library and Export MP4, and played a real Radio station. iPad captures were rotated from the simulator's landscape buffer. Callouts in `callouts.js` are magnified crops of the same captures; no interface is generated or edited.

## Rebuild

```bash
PLAYWRIGHT=/Users/brad/Documents/GIT_SOURCE/jotley-site/node_modules/playwright/index.mjs node render.mjs
```

Open `layouts.html?device=iphone&review=1` (or `device=ipad`) for a contact sheet, `&slide=N` for one full-size slide. `manifest.json` records dimensions and SHA-256 of each release PNG.

Status: prepared for review only. Nothing has been uploaded to App Store Connect.

## Header animation and search-results image

Built like Jotley's `jotley-2.0-bright-v1/header3.html` and `search4.html`:

- `release/en-US/header-animated-3840x1646.mp4` — 12 s seamless loop, 30 fps, H.264 High, no audio track. Every motion in `header.html` is periodic in the loop length; the lockup stays inside the centred 1646×660 area the App Store keeps on iPhone.
- `release/en-US/search-results-3840x2560.png` — `search.html`, using the real full-screen and Radio captures.
- `header-review-1920.mp4` is a small review copy; do not upload it.

Rebuild both with `node render-header.mjs video` (same `PLAYWRIGHT` variable as above).

**Chosen header (Oct 20):** `release/en-US/header-animated-dark-3840x1646.mp4` from `header-dark.html` (`node render-header.mjs video header-dark`). Earlier light variants are kept for reference: `header-animated-3840x1646.mp4` (deep violets), `header-animated-v2-colorful-3840x1646.mp4`, `header-animated-v1-3840x1646.mp4`.
