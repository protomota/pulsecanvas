# Component and asset rights

## Unresolved Apple-store blocker — upstream guidance reviewed 2026-10-12

The official [projectM licensing wiki](https://github.com/projectM-visualizer/projectm/wiki/projectM-Licensing#apple-store-compatibility)
explicitly states incompatibility with Apple's stores, including macOS, and
recommends standalone DMG/PKG distribution subject to LGPL compliance. Record this
as a separate unresolved release blocker. Dynamic linking, an MIT or other
wrapper license, Apple's EULA exception and a matching source archive do not
resolve it. Existing engine-source/rebuild/signing work is retained as engineering
evidence. It does not establish Apple-store compatibility or authorize submission
or a distribution-channel change.

PulseCanvas's first-party source code is governed by the PulseCanvas Source-Available Noncommercial License in the root LICENSE. Commercial source reuse, resale, and commercial forks require separate written permission; using the official application to make commercial videos remains permitted. Dependencies, preset authors' works, textures, and music retain their own licenses, including commercial permissions and required LGPL modification/relinking rights. Preserve author names, catalog original titles, and all upstream notices. No presets have been removed for licensing as part of this preparation. Earlier MIT-licensed releases retain their original terms; this change is not retroactive.

| Component | Evidence / terms | Release status |
|---|---|---|
| PulseCanvas first-party code, native shaders and build scripts | Root LICENSE, PulseCanvas Source-Available Noncommercial License | Include exact notice; commercial code reuse requires separate permission; official-app video production allowed |
| Native shader resources / geometry | AIR source modules and geometry verification notes; Brad says he created the shaders | Creator attestation recorded; no separate shader license requested |
| ProjectM 4.2.0 source snapshot | `third_party/projectm-source.tar.gz`, upstream commit 349b7cc2db312d47cef6be24c6856ced6643a385; LGPL 2.1 or later | Source, notices, rebuild/relink route and distribution terms required |
| projectm-eval / hlslparser | Embedded source LICENSE files, MIT | Included in generated Legal resources |
| stb_image and extensions | Full source notices bundled; ordinary stb code has MIT/public-domain choice | Preserve each extension's separate notice; PowerVR decompression in stbi_pvr_c.h credits Imagination Technologies without an accompanying grant, which remains unresolved |
| 7,838 ProjectM presets | Pinned manifest + unchanged .milk sources, original paths/metadata, full notice scan, unchanged README/LICENSE; curator confirmed ISOSCELES credit/link in issue #8 | **Unresolved** individual permissions; inclusion guidance and upstream public-domain assumption are not documented grants from every author |
| 67 texture images | Separate pinned manifest + unchanged upstream README and image bytes | **Unresolved** grants for the individual assets; independent of engine and preset terms |
| PulseCanvas.mp3 | Brad created the track using Suno and confirms commercial-use rights; wants free reuse | User attestation accepted; not described as MIT or a formally licensed open-source work |
| Promotional narration | Brad confirms narration is his | Ownership attestation recorded; existing videos remain unpublished |

Suno terms checked 2026-10-11 (effective 2026-09-03) permit commercial exploitation of eligible output obtained through permitted downloads; free/basic output and remixes have separate restrictions. Brad confirms commercial-use rights for this track. Retain original provenance/metadata and the track/download record privately with release evidence. There is no requirement here to invent a separate music license. A website can host creator-provided music/provenance when approved. https://suno.com/terms

## LGPL engineering and distribution

The app dynamically opens `Contents/Frameworks/libprojectM.dylib`. PulseCanvas code is source available and can be rebuilt subject to the root LICENSE, which explicitly preserves required LGPL modification/relinking rights for the customer's own use, including commercial own use. The matching engine source includes its vendor code and build configuration; prepare it with `scripts/package-store-source.sh`. Provide the archive alongside the app download/listing source page, with no authentication/paywall. Keep that exact archive per release rather than only pointing to a moving upstream branch.

LGPL 2.1 sections 4 and 6 require the applicable notices/license and an allowed route to modify/relink the library; section 6 also requires terms allowing modification for the customer's own use and reverse engineering for debugging those modifications. Complete application source and library source/build scripts are the proposed section 6(a) route. The scripts compile the engine as a shared library, build the source-available app and sign a local test copy. The root LICENSE preserves those required rights rather than imposing the noncommercial restriction on them. The repository contains rebuildable AIR IR; recipients need the compatible Apple build tools. Validate the source package from a fresh checkout before claiming completeness.

Distribution-signed apps require matching-team nested signatures, so merely replacing a dylib in an installed App Store app is insufficient. Do not promise unrestricted in-place replacement and do not disable library validation. A rebuilt app/library must be signed as a complete local build. Apple's current Standard EULA, section (a), expressly excepts rights permitted by the licenses of included open-source components from its copying/modification/reverse-engineering restrictions (checked 2026-10-11: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/). A custom EULA is therefore not automatically required merely because the engine is LGPL. Public corresponding source and the practical rebuild/relink route remain necessary under the proposed distribution route; this exception does not grant redistribution rights for unrelated presets or textures. The Standard EULA remains selected in Apple.

Proposed third-party EULA supplement (review before use): “Third-party components remain governed by their included licenses. Nothing in these application terms restricts modification for your own use or reverse engineering for debugging modifications to components licensed under the GNU Lesser General Public License, or other rights granted by those licenses. Corresponding source and build instructions are provided with each release.” The planned source URL is https://pulsecanvas.si/source/; publication remains pending.

## Workable resolution for preset and texture packs

Prepare a per-file inventory and preserve credits. Establish express redistribution grants from upstream/authors or an authoritative license/provenance record for each shipped pack. If that cannot be established, offer the user a specifically identified, expressly licensed replacement pack or a native-only store edition as a product choice; **do not silently remove thousands of effects or change the promised count**. Free price and public availability do not resolve missing permissions. Publishing source helps LGPL obligations but does not create grants for unrelated third-party assets.

Actual stb build compiles image_DXT.c, stb_image.c and wfETC.c with the extension headers. image_DXT.c expressly says public domain; stbi_pvr_c.h contains Imagination Technologies PVRTDecompress copyright/provenance, with no separate permission grant found in this snapshot. Obtain the applicable grant or an upstream-authorized replacement before treating the vendor snapshot as fully cleared. `build/app-store/asset-rights-inventory.csv` records each preset/texture hash and original credit without inventing a license.


## Full-effects route selected — 2026-10-11; curator reply reviewed 2026-10-12

Brad chose to retain all effects and prepare rights/source resolution. The preset curator confirmed the ISOSCELES credit/link in [issue #8](https://github.com/projectM-visualizer/presets-cream-of-the-crop/issues/8#issuecomment-6132611267), described uncertain licensing and mashup provenance, and did not establish grants from every author. The app's Legal & Credits UI and source documentation now retain that credit. The separate manifests and notice inventory are described in [Provenance.md](../../Sources/PulseCanvas/Resources/ProjectM/Provenance.md). Original presets, texture bytes and engine-source work remain intact. Exact issue links/bodies and historical staged source evidence are in RIGHTS-RESOLUTION.md. No private repository was made public; public source publication remains pending.
