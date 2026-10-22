# All-device App Store artwork

Matching availability slides for iPhone, iPad, iPhone Duo, Mac and Vision Pro.
Copy: **On all your devices.** — **iPhone · iPad · Mac · Vision Pro**.
The four device cards contain real native app captures, using the current app icon.

Render with Node and Playwright, passing an absolute capture directory and an
output directory outside Git:

```sh
node assets/app-store/all-devices-1.2/render.mjs /absolute/captures /absolute/output
```

Set `PLAYWRIGHT` to an absolute Playwright module path if it is not installed in
the local Node environment. Required captures: `iphone-studio.png`,
`ipad-studio.png`, `mac-studio.png`, `vision-studio.png`.
The renderer checks image decoding, text bounds and copy/device overlap, then
writes five native-size PNGs and a checksum manifest.

October 22 delivery: appended to all five screenshot groups, last in each group.
See `docs/releases/controls-testflight-1.2-2026-10-22.md` for final counts and evidence.
