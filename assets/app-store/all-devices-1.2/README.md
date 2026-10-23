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
`ipad-studio.png`, `mac-studio.png`, `vision-studio.png`, and
`duo-closed-studio.png`.
The renderer checks image decoding, text bounds and copy/device overlap, then
writes five native-size PNGs and a checksum manifest.

October 22 delivery: appended to all five screenshot groups, last in each group.
See `docs/releases/controls-testflight-1.2-2026-10-22.md` for final counts and evidence.

The refined montage uses four different effects: iPhone Ink Bloom, iPad Chrome
Reef, Mac Octagon Vault and Vision Pro LED Corridor. Its source folder is
`/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/variety/montage-sources/`.
The generic source filenames are retained for the renderer; their SHA-256 hashes
identify the exact native captures.

The Duo-format slide uses the native closed Duo capture in its phone card, names
it iPhone Duo and uses the same wording in the subtitle. The other four formats
retain their existing phone card and are byte-identical. Current source folder:
`/Users/brad/Documents/Codex/2026-10-22/pulsecanvas-controls-release-rescue/art/closed-duo/montage-sources/`.


October 23 shell correction: the Duo card now follows Device Hub’s closed form:
straight left hinge, rounded right corners and outer camera cutout. The native
closed-display image and its aspect ratio are preserved. Only the Duo-format
output changes; the other four formats remain byte-identical. Corrected renders
are under `art/duo-folded-shell/all-devices/` in the internal artifact folder.
