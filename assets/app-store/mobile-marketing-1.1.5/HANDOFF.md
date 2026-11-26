# Handoff: PulseCanvas Studio iOS 1.1.5 App Store media

Copy everything below into a new session to finish the App Store Connect upload.

---

You are uploading finished App Store media for **PulseCanvas Studio iOS 1.1.5** (App ID 6821642700). The build is TestFlight 1.1.5 (5). All artwork is done and approved. Do not redesign anything. Upload it and stop before **Add for Review**/**Submit for Review**; Brad submits himself.

## Where everything is

Folder: `/Users/brad/Documents/GIT_SOURCE/pulsecanvas-studio/assets/app-store/mobile-marketing-1.1.5/` (not committed yet; ask Brad before committing).

Upload-ready files are in `release/en-US/`:

| Slot in App Store Connect | File(s) | Size |
| --- | --- | --- |
| iPhone 6.9" screenshots (in this order) | `iphone-01-music.png` … `iphone-06-free.png` | 1320 × 2868, opaque RGB |
| iPad 13" screenshots (in this order) | `ipad-01-music.png` … `ipad-06-free.png` | 2752 × 2064 landscape, opaque RGB |
| Header (Header and Search Results → Header) | `header-animated-dark-3840x1646.mp4` — **the chosen one** | 3840 × 1646, 12 s seamless loop, 30 fps, H.264, no audio, 31 MB |
| Search Results (Header and Search Results → Search Results) | `search-results-3840x2560.png` | 3840 × 2560 |

Do not upload: `header-animated-3840x1646.mp4` (light alternative), `header-animated-v1-…`, `header-animated-v2-colorful-…`, `header-review-1920.mp4`, `header-dark-review-1920.mp4`, the contact sheets, or anything in `sources/`.

Slide order and copy: 1 Your music. A new world. (300+ Metal visualizers) · 2 Build a visual journey. · 3 Shape every look. · 4 Tune in to Radio. · 5 From your phone/iPad to their feed. (4K60) · 6 Completely free.

## Where to upload

Open https://appstoreconnect.apple.com/apps/6821642700/distribution/ios/version/inflight (Brad is signed in in Chrome). The iOS 1.1.5 page has two tabs under **Product Page Information**:

1. **Header and Search Results.** There's a **Header** sub-tab ("0 of 1 Header Asset", supported sizes 5244 × 2950 and 3840 × 1646) and a **Search Results** sub-tab. Each has **Upload** / **Browse Assets** links and a drag-and-drop area. Asset Library is in the left sidebar under Growth & Marketing if uploads need to go there first.
2. **App Previews and Screenshots.** Upload the iPhone 6.9" and iPad 13" sets in numbered order. Remove any older images in those slots first.

Then click **Save** (top right). Do not click **Add for Review**.

Watch out: Claude in Chrome's `file_upload` accepts at most 10 MB per call. The header MP4 is 31 MB, so either have Brad drag it in, or use the App Store Connect API (`scripts/app-store-api.py` with key `~/.private_keys/PulseCanvas/AuthKey_6SX73KLRP9.p8`; Brad must supply the Issuer ID from https://appstoreconnect.apple.com/access/integrations/api). Ask Brad before re-encoding the header to a smaller file.

## How it was built (only if a change is needed)

- Screenshots: `layouts.html` + `callouts.js`, rendered by `render.mjs`. Header: `header-dark.html` (light alternative `header.html`). Search image: `search.html`. Header and search are rendered by `render-header.mjs [stills|video] [header|header-dark]`. Run each with `PLAYWRIGHT=/Users/brad/Documents/GIT_SOURCE/jotley-site/node_modules/playwright/index.mjs`.
- All UI in the images is real captures of the 1.1.5 build from the iOS simulator (iPhone 17 Pro Max, iPad Pro 13" M5), in `sources/`. See `README.md`.
- Brad's preferences: light backgrounds for screenshots; the header is the one dark piece (icon's glowing violets on near-black); no multicolor pastel palettes; say "300+" not an exact count; no narration or audio in the header.
- Unused draft: App Preview video projects at `/Volumes/Music/Video/astra_video/videos/pulsecanvas-mobile-appstore/` (not requested; ignore).
