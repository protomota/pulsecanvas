# Current iOS search-results graphic

Retains the approved campaign layout, typography, colors and feature copy while
refreshing both phone images from the current app. The Radio image shows the
presentation button in the top header. No app UI is reconstructed.

```sh
node assets/app-store/search-marketing-1.2/render.mjs /absolute/captures /absolute/output
```

Set `PLAYWRIGHT` to an absolute Playwright module path if necessary. Required
captures: `iphone-fullscreen.png` and `iphone-radio.png`. The renderer uses the
current app icon, checks decoded images and device bounds, and writes the
3840 × 2560 PNG with a source/output checksum manifest. Keep renders outside Git.

Uploaded to the English (U.S.) iOS 1.2 search-results asset on October 22, 2026.
The existing header video was retained.
