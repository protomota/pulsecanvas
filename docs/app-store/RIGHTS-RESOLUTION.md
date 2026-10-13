# Full-effects release: rights and source resolution

## Edition split — current decision, 2026-10-12

The owner subsequently authorized two editions. The App Store package now contains
31 native Metal visualizers and excludes projectM, OpenGL presets, the external
texture pack and Sparkle. The direct edition retains the full library and separate
LGPL/source, preset and texture provenance obligations. The Apple-store engine
warning below applies to packages containing projectM; it is not resolved by
dynamic linking or a source archive. Asset permissions in the direct edition remain
unresolved. Historical decisions below are preserved and superseded by this split.
See [DISTRIBUTION.md](../DISTRIBUTION.md) for actual build/testing status.

## Native catalog update — 2026-10-13

The 13 extracted AIR shader modules, the point/mesh geometry translated from another
application, and the native designs built on them (IDs 0–3, 5–9, 11, 13 and 14) were
removed from the source tree, along with ID 30, which duplicated ID 22. Their IDs remain
reserved so saved projects open a replacement design. The native catalog is now 187
original PulseCanvas designs compiled from Metal source at runtime; no extracted or
prebuilt shader modules remain. Rows below that mention AIR modules or geometry
verification describe the earlier state. Store metadata and the App Store build still
describe the submitted 31-visualizer version until a new release is prepared.

## Current unresolved release blockers — 2026-10-12

- **Apple-store compatibility:** the [official engine licensing wiki](https://github.com/projectM-visualizer/projectm/wiki/projectM-Licensing#apple-store-compatibility)
  explicitly warns against Apple's stores, including macOS, and recommends
  standalone distribution subject to LGPL terms. Dynamic linking, a wrapper
  license, EULA exceptions and source archives do not resolve this blocker.
  This update neither submits a release nor changes its distribution channel.
- **Preset permissions:** the [curator's reply](https://github.com/projectM-visualizer/presets-cream-of-the-crop/issues/8#issuecomment-6132611267)
  confirms the exact ISOSCELES credit/link and describes missing licenses,
  anonymous authors and uncertain mashup provenance. Community treatment as BSD
  is historical context, not a verified BSD grant. Individual permissions remain
  unresolved. Attribution alone does not settle them.
- **Texture permissions:** independent asset grants remain unresolved. The
  inclusion recommendation in the texture README is not per-image licensing.
- **PVRTC vendor provenance and public corresponding source:** the existing
  unresolved work remains; this update does not claim either is cleared.

The app and source package retain the exact credit, pinned upstream README and
LICENSE bytes, all 7,838 original preset paths/bytes and original creator metadata.
Separate manifests record preset/texture hashes and deterministic display-name
mapping. A line-numbered keyword scan covers every preset, with complete hashes
preserving notices even where the scan does not identify them. See
[Provenance.md](../../Sources/PulseCanvas/Resources/ProjectM/Provenance.md).
The source package records version/build and commit and retains engine source and
rebuild scripts. Earlier source archives and the historical evidence below are
preserved; they do not describe a newly published download.

Owner selected the full-effects route on 2026-10-11. Retain all 31 native visualizers, 7,838 presets and 67 texture images. No native-only edition or removal is authorized by this decision. Own shaders, narration and the commercial-use Suno soundtrack are already accounted for.

## Evidence and precise questions

| Material | Exact upstream snapshot | Evidence | Remaining question |
|---|---|---|---|
| Cream of the Crop presets | `0180df21f5e0bd39b9060cc5de420ed2f1f9e509` | Original notice assumes public domain; original curator also says the pack is intended for inclusion in projectM-based applications and welcomed inclusion in a free project with attribution | Confirm applicable redistribution basis for the shipped subset in a free Mac App Store app and downloadable matching source, including the original authors' rights |
| Milkdrop texture pack | `6368812f27bc747b517218fbf89d21d59afce4d9` | README recommends including the pack in applications with presets; no separate license found | Confirm applicable terms/authorizations for these 67 images and public source copies |
| PVRTC decoder in ProjectM 4.2.0 | Engine `349b7cc2db312d47cef6be24c6856ced6643a385`; `vendor/stb_image/stbi_pvr_c.h` | Embedded Imagination Technologies copyright; modern official PowerVR SDK is MIT licensed | Confirm the grant applicable to this exact older decoder/port, rather than assuming the modern SDK license applies to all historical copies |

Curator evidence is meaningful inclusion/attribution guidance, not evidence that every individual author supplied a license or that the curator can grant all authors' rights. Do not describe the whole pack as MIT or claim no third-party content in Apple. Existing credit metadata and upstream notices remain intact; renamed display titles are separate presentation metadata.

Required curator credit:

> Cream of the Crop pack curated by ISOSCELES

https://www.patreon.com/posts/pack-nestdrop-91682111

Primary evidence reviewed:

- https://github.com/projectM-visualizer/presets-cream-of-the-crop/blob/master/LICENSE.md
- https://github.com/projectM-visualizer/presets-cream-of-the-crop/issues/3 (original curator's application-inclusion statement)
- https://github.com/projectM-visualizer/presets-cream-of-the-crop/issues/2#issuecomment-4180111083 (curator's requested credit)
- https://github.com/projectM-visualizer/presets-milkdrop-texture-pack/tree/6368812f27bc747b517218fbf89d21d59afce4d9
- https://github.com/powervr-graphics/Native_SDK/blob/master/LICENSE.md

## Prepared outbound requests

Owner explicitly authorized posting all three requests. They were posted as `protomota` on 2026-10-11, and each open issue's author/title/body was verified against the approved draft. The GitHub connector returned a definite 403 without creating an issue; the authenticated GitHub CLI completed the posts. No duplicate issue was created.

- Presets: https://github.com/projectM-visualizer/presets-cream-of-the-crop/issues/8
- Textures: https://github.com/projectM-visualizer/presets-milkdrop-texture-pack/issues/3
- PVRTC: https://github.com/projectM-visualizer/projectm/issues/1046

Exact bodies remain in `rights-requests/01-presets.md`, `02-textures.md`, and `03-pvrtc.md`. They identify the app, free-store/source distribution, pinned upstream versions and preserved credits. No private signing/account/contact details or project bookmarks are included. They ask for existing terms/provenance or an authorized grant; they do not ask a curator to grant rights they do not hold. **The preset curator replied on 2026-10-12 as recorded above; permissions remain unresolved.** The issue's MIT wording describes an earlier license state; the current root license is source-available noncommercial, with third-party rights kept separate.

Additional vendor evidence: the official PowerVR SDK tag `R14.2-v3.4` includes `LICENSE_POWERVR_SDK.txt` with an Imagination MIT grant and `Tools/PVRTDecompress.cpp`. Local copies are retained in `work/app-store/rights-evidence/`. This is helpful historical evidence, but the bundled decoder/port is not byte-identical to that implementation, so the precise provenance/notice query remains appropriate.

## Source publication package

- Release source: `build/app-store/PulseCanvas-1.0.0-2-source.tar.gz`.
- SHA-256: `eb1f677dbbe687d8ff6ab08acf9bb52292341e791b329e964129de2c1e396eb3`.
- Source revision: `a8f7e93f481b7f99a21305789af47d32e70cc6f7`; same application code as store build 2, plus listing documentation/assets.
- Exact preset/texture inventory: `build/app-store/asset-rights-inventory.csv` (includes the texture README as a provenance row in addition to 67 images).
- Standalone `/source/` page, immutable download and checksum are staged in `build/app-store/source-publication/`. This is a local review/publication package, not a live URL or permission grant.
- Library source includes vendor code/build configuration. Swift application source and rebuildable AIR resources are included. Rebuild/relink instructions use the user's own signing identity; no signing keys/profiles/bookmarks are distributed.
- Source archive contains only the release snapshot, not repository history or unrelated private work. Its contents remain local while the particular third-party rights questions are resolved.
- Local review page: http://127.0.0.1:3991/source/ (loopback-only server started for review). The HTML and three relative download targets exist; the browser's archive click received HTTP 200 from the local server, although its download-completion event was not reported by the browser tool. The staged archive's checksum and required build inputs were independently verified. This does not verify an anonymous public download.

Future publication requires resolving the separate Apple-store warning as well as
asset permissions and corresponding-source obligations. Retain the existing
source/rebuild route, but do not treat it as sufficient for Apple distribution.
No publication, upload, review submission or channel change is authorized by this
attribution update.
