ProjectM integration sources

Cream of the Crop pack curated by ISOSCELES

https://www.patreon.com/posts/pack-nestdrop-91682111

- Engine: https://github.com/projectM-visualizer/projectm/tree/349b7cc2db312d47cef6be24c6856ced6643a385 (4.2.0).
- Presets: https://github.com/projectM-visualizer/presets-cream-of-the-crop/tree/0180df21f5e0bd39b9060cc5de420ed2f1f9e509 (9,795 upstream .milk files; 9,783 well-formed source entries before performance/visibility curation; current bundle contains 7,838 presets).
- Textures: https://github.com/projectM-visualizer/presets-milkdrop-texture-pack/tree/6368812f27bc747b517218fbf89d21d59afce4d9.

`projectm-source.tar.gz` contains the unmodified engine and bundled dependency source, including upstream license notices. Website images, the example desktop background, Git metadata, and build/install products are omitted. `scripts/build-projectm.sh` compiles this source with CMake. The app dynamically loads `Contents/Frameworks/libprojectM.dylib`, which can be rebuilt and replaced independently of PulseCanvas. The engine's LGPL 2.1 text and the preset pack's author/copyright notice are included in app resources. Original preset titles and author credits remain in catalog metadata, searchable in the Library and visible on hover. Two-word display names and shared icons are PulseCanvas presentation metadata; `.milk` source files are unchanged.

The preset pack's own notice says most preset authors did not supply explicit licenses; its public-domain statement is an upstream assumption, not a new license grant by PulseCanvas. Preserve that notice and original creator credits when distributing the pack. Texture assets retain the upstream pack's provenance.

The curator confirmed the exact credit/link in issue #8 on 2026-10-12, while
explaining that original author licenses and mashup provenance remain uncertain:
https://github.com/projectM-visualizer/presets-cream-of-the-crop/issues/8#issuecomment-6132611267.
This does not establish permission from every author or a BSD license for the
presets. `Resources/ProjectM/Preset-README.md` and `Preset-notice.md` retain the
pinned upstream README/LICENSE bytes unchanged. `preset-manifest.json` records
the 7,838-file subset with original paths, SHA-256, creator titles and display
mapping; `preset-notices.json` scans every file for notice candidates.
`texture-manifest.json` independently inventories 67 images plus their README.
The manifests and [provenance note](../Sources/PulseCanvas/Resources/ProjectM/Provenance.md)
are included in both app Legal resources and version/revision-matched source.

**Unresolved Apple-store release blocker:** upstream's official licensing wiki
explicitly says projectM applications cannot be published via Apple's stores,
including macOS, and recommends standalone distribution subject to LGPL terms:
https://github.com/projectM-visualizer/projectm/wiki/projectM-Licensing#apple-store-compatibility.
Dynamic linking, an MIT or other wrapper license, an EULA exception and source
availability do not resolve that warning. No channel change, engine removal or
App Store submission is part of this provenance update.

Store preparation bundles additional component notices in Contents/Resources/Legal. The hardened-runtime store target signs the engine and app with the same team. A replacement library cannot simply retain the original store signature: rebuild/relink and sign a complete local app, and review the source-distribution and App Store terms described in docs/app-store/LICENSES.md. This note does not establish previously missing preset/texture grants.
