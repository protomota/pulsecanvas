# Preset and texture provenance

Cream of the Crop pack curated by ISOSCELES

https://www.patreon.com/posts/pack-nestdrop-91682111

This exact pack-level credit was confirmed by the curator in
https://github.com/projectM-visualizer/presets-cream-of-the-crop/issues/8#issuecomment-6132611267
on 2026-10-12. The curator described missing original licenses, anonymous aliases
and mashup histories, and did not determine a definitive license for the pack.
The reply is attribution and provenance guidance, not permission from every author.

## Presets

Upstream: https://github.com/projectM-visualizer/presets-cream-of-the-crop/tree/0180df21f5e0bd39b9060cc5de420ed2f1f9e509

Pinned commit: `0180df21f5e0bd39b9060cc5de420ed2f1f9e509`.
The upstream tree has 9,795 `.milk` files. PulseCanvas bundles a curated subset of
7,838, not the whole repository. `preset-manifest.json` records every actual
bundled path, upstream path, SHA-256, stable identity, original creator/title and
display label. Paths and filenames are unchanged. Presentation labels do not
replace original creator metadata, equations, shaders or embedded notices.

`Preset-README.md` and `Preset-notice.md` are byte-for-byte copies of the pinned
upstream README.md and LICENSE.md. The README intends inclusion in projectM
applications. The LICENSE describes an upstream public-domain assumption despite
missing original licenses. Neither supplies documented grants from every author.
Individual preset redistribution permissions remain unresolved; do not describe
the subset as MIT, BSD, verified public domain or legally cleared.

`preset-notices.json` records line-numbered notice/credit/license/URL candidates
from scanning every bundled preset. The scan is conservative evidence gathering,
not legal classification or a guarantee of identifying every notice. Full-file
hash verification preserves all bytes, including notices the keyword scan misses.
Filename credits and originalTitle metadata are retained for every preset.

## Textures — separate unresolved permissions

Upstream: https://github.com/projectM-visualizer/presets-milkdrop-texture-pack/tree/6368812f27bc747b517218fbf89d21d59afce4d9

Pinned commit: `6368812f27bc747b517218fbf89d21d59afce4d9`.
`texture-manifest.json` records the 67 bundled images and unchanged upstream README
with original paths and SHA-256 hashes. The README recommends inclusion alongside
presets; it does not supply per-image license grants. Texture permissions remain
unresolved separately from presets, application code and the engine. Attribution
does not settle either asset pack's permissions.

## Application and engine — independent terms

Current first-party code uses the root PulseCanvas Source-Available Noncommercial
License, not MIT. Earlier MIT releases retain their original terms. That license
does not relicense third-party materials. projectM 4.2.0 remains LGPL 2.1 or later;
its vendor components retain their own notices. Matching engine source and
rebuild/relink scripts are retained. See `third_party/PROJECTM.md` and
`docs/app-store/LICENSES.md` in the source package.

## Unresolved Apple-store release blocker

Official engine guidance, reviewed 2026-10-12:
https://github.com/projectM-visualizer/projectm/wiki/projectM-Licensing#apple-store-compatibility

Upstream explicitly states that apps containing projectM cannot be published via
Apple's stores, including the macOS Store, and recommends standalone DMG/PKG
distribution subject to LGPL compliance. This warning is a separate unresolved
release blocker. Dynamic linking, a wrapper license (including MIT), an EULA
exception and a matching source archive do not resolve it. This attribution
update does not authorize submission, publication, a distribution-channel change
or an engine replacement. Existing source/rebuild work remains engineering
evidence, not a claim of Apple-store compatibility or cleared asset rights.

## Verification from source

Run `python3 scripts/preset-provenance.py` from the source checkout. To regenerate
from Git objects at the pins, add `--generate --presets-checkout PATH
--textures-checkout PATH`. Regeneration verifies all bundled bytes against the
upstream snapshots before recording them. Run with `--app PATH` and/or
`--source PATH --revision COMMIT` to inspect actual generated artifacts. Builds
verify provenance and copy these notices/manifests into the accessible Legal
directory. Source packaging verifies the committed subset and engine snapshot.
