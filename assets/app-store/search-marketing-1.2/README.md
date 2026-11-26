# Current iOS search-results graphic

Retains the approved campaign layout, typography, colors and feature copy while
pairing a purple full-screen visualizer capture with the current Studio capture. The Studio image shows all six actions in two
aligned rows: Library, Presentation, More, Shuffle, Dice and Visual Style. No app UI is reconstructed.

```sh
node assets/app-store/search-marketing-1.2/render.mjs /absolute/captures /absolute/output
```

Set `PLAYWRIGHT` to an absolute Playwright module path if necessary. Required
captures: `iphone-fullscreen-alternate.png` and `iphone-studio.png`. The renderer uses the
current app icon, checks decoded images and device bounds, and writes the
3840 × 2560 PNG with a source/output checksum manifest. Keep renders outside Git.

Uploaded to the English (U.S.) iOS 1.2 search-results asset on October 22, 2026.
The existing header video was retained.

The alternate full-screen image is the preserved native purple ribbon capture
from the earlier campaign. It contains no editor controls. The Studio image uses
LED Corridor and retains all six current toolbar buttons.
