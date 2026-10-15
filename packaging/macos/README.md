# PulseCanvas Studio Mac installer

The direct-download installer follows the completed Jotley installer at commit
`0a0878f71d5ceeeb51bfe59bd4702d3c97b5bb73`. Its real Finder window is saved at
`(160, 160)`, size 720 × 520 points. Original artwork occupies 720 × 460 points,
leaving room for Finder chrome. The real app is at `(195, 230)` and the real
`Applications` symlink to `/Applications` is at `(525, 230)`. Icons are 104 points;
labels are 15 points, below the icons. Sorting is disabled and scroll offset is zero.

The brand base is `#17121b`, taken from PulseCanvas's existing website, with a soft
charcoal/plum glow, lilac arrow and peach dotted outline. The native SF system font
retains Jotley's 30/16/15/14-point instruction sizes. The renderer checks text width
so the full PulseCanvas Studio name fits. Pale wells keep native black labels readable.

`background.png` is 720 × 460 pixels at 72 dpi; `background@2x.png` is 1440 × 920
pixels at 144 dpi. `background.tiff` contains both representations. Regenerate on
macOS with Pillow and the native font:

```sh
python3.12 -m venv .build/dmg-artwork
.build/dmg-artwork/bin/python -m pip install Pillow==12.3.0
.build/dmg-artwork/bin/python packaging/macos/generate-background.py
```

The packaging dependencies are pinned build tools and do not ship in the app:

```sh
python3.12 -m venv .build/dmg-tools
.build/dmg-tools/bin/python -m pip install -r packaging/macos/requirements.txt
```

## Signing and packaging

The existing `build-direct-release.sh` and `sign-direct-release.sh` remain responsible
for building and signing the direct edition, its Sparkle framework, XPC services and
helpers. The signing script embeds `PulseCanvasInstallerBackground.tiff` in
`Contents/Resources` before final signing, including when signing is retried.
Packaging does not modify the signed bundle, add FinderInfo or hide its extension.
The `.DS_Store` background alias refers to that embedded file; there is no loose
root background file or directory.

To build, package, sign, notarize, staple and verify locally, supply an **existing**
notarytool Keychain profile. This does not create credentials, publish artifacts,
modify the website or submit an App Store release:

```sh
./scripts/release-direct-dmg.sh "$NOTARYTOOL_PROFILE"
```

`DIRECT_APP` can point to an already-built, signed app. `DIRECT_DMG` can choose a
fresh output path; existing DMGs are never overwritten. `DMG_PYTHON` can select
another Python 3.12 environment with the exact pinned packages. The default output
is `build/direct-distribution/PulseCanvas-Studio-VERSION-BUILD.dmg`. If packaging
already completed, resume the exact image without rebuilding the app:

```sh
./scripts/release-direct-dmg.sh "$NOTARYTOOL_PROFILE" --resume
```

Resume first verifies that the mounted image exactly matches the signed source app.
It retains a valid image signature from the expected Developer ID identity, then
submits that image for notarization, staples it, and regenerates the update signature.

For a packaging/layout check of a prepared signed direct app:

```sh
.build/dmg-tools/bin/python scripts/package-mac-dmg.py \
  --app 'build/direct/PulseCanvas Studio.app' \
  --output build/direct-distribution/PulseCanvas-Installer-Check.dmg
```

After signing, notarization and stapling, inspect the actual final compressed image:

```sh
.build/dmg-tools/bin/python scripts/package-mac-dmg.py \
  --app 'build/direct/PulseCanvas Studio.app' \
  --output build/direct-distribution/PulseCanvas-Studio-VERSION-BUILD.dmg \
  --verify-only --release-checks
```

The verifier mounts the actual image read-only. It checks the app and symlink,
saved window/view/icon geometry, all five disabled chrome settings, sorting,
scroll offset, label placement and size, complete background alias path, exact
artwork bytes, and all bundle file hashes, permissions and symlink targets. It
checks strict deep app signatures and the existing direct bundle identifier,
feed URL and public update key. Release checks additionally require a valid DMG
signature/staple and Gatekeeper acceptance of the mounted app. The release script
also assesses the DMG and signs/verifies its Sparkle enclosure, including an
independent CryptoKit verification against the pinned public key.

Each image has a `.layout.json` report. Completed releases additionally have
`.notarization.json` and `.release.json` reports. They contain only public metadata.
The release report records `published: false`; uploading the DMG, matching source
archive and appcast is a separate release step. Existing appcast files are untouched.
This packaging work does not clear licensing or other release blockers.

## Real Finder inspection

Open the final DMG and inspect its default native window. Confirm both actual
draggable items, readable labels, complete heading/subtitle/footer, arrow and dotted
border. The artwork must fit even if Finder retains a user-selected status bar.
Inspect with Show Hidden Files enabled too: `.DS_Store` is required metadata, and
there must be no third background item. Never change global Finder preferences to
force the layout. Save an actual window screenshot with a versioned filename;
artwork-only exports are not installer screenshots.

Reference source: [Jotley installer commit](https://github.com/protomota/jotley-app/commit/0a0878f71d5ceeeb51bfe59bd4702d3c97b5bb73).
