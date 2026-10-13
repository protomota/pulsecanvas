# PulseCanvas editions and release checks

## Version 1.0.2 (10), checked 2026-10-12

| Edition | Build | Resources | Update channel |
| --- | --- | --- | --- |
| Mac App Store | `STORE_BUILD`, generated Xcode project | 31 native Metal visualizers, native palettes/icons, demo MP3 and application license; no projectM, `.milk` presets or external textures | Apple |
| Direct download | `DIRECT_BUILD`, `scripts/build-direct-release.sh` | Native library plus original 7,838 presets, 67 textures and their unchanged provenance/notices; projectM shared library | Sparkle 2.10.0 |
| Local development | `scripts/build-app.sh` | Full library | No bundled updater |

The application license remains source-available noncommercial. Earlier MIT grants
remain in force for those versions. Third-party terms remain separate. The official
application may be used to make commercial videos; source reuse and asset rights
are different questions.

The full-library engine's upstream licensing wiki warns against Apple-store
distribution. Dynamic linking, a wrapper license or corresponding source does not
resolve that warning. The Store artifact excludes that engine entirely. Individual
preset and texture permissions in the direct edition remain unresolved; the split
is not a claim of permission or clearance for them. Preserve all provenance,
notices and original bytes in the full edition.

## Preferences and project compatibility

The Store edition migrates native visual styles and favorites into separate
`PulseCanvas.metalStudio.v1` and `PulseCanvas.metalEffectFavorites.v1` preferences.
The full-library preferences remain intact. Projects with native scenes can be
opened in either edition. Projects using a full-library preset fail clearly in the
Store edition before replacing the current project/session; open them in the direct
edition instead. Soundtrack references and native settings are retained.

## Build and validate

```sh
./scripts/test-store-edition.sh
./scripts/store-release.sh test
python3 scripts/validate-store-artifact.py --local ".build/store-test/Build/Products/Release/PulseCanvas Studio.app"
```

The generated Store project excludes ProjectMEngine.swift and AppUpdater.swift.
`prepare-store-resources.sh` stages only the intended native resources. The artifact
validator checks the actual packaged app, including linked/undefined symbols,
resources, signing team, sandbox, version and updater keys. It rejects preset files,
projectM/OpenGL dependencies and Sparkle. Check both the archive and the app expanded
from the final installer, not just the source configuration.

Version 1.0.2 (10) was successfully archived, distribution-exported, expanded and
validated. Apple accepted its upload on 2026-10-12. App Store Connect subsequently
showed **Testing** in the existing **PulseCanvas Mac Beta** internal group. The
prepared 1.0.2 Store version has build 10 attached and metadata describing 31 Metal
visualizers. This update does not submit the version for App Review or publish it.
Listing screenshots and the historical age-rating answers must be rechecked before
an App Review submission.

Checks passed: 31-effect catalog, non-destructive preference migration, incompatible
project handling, offline GPU frames, decoded native exports, deterministic
zero-Chaos behavior, full-library Studio regression suite and projectM rendering/
mixed export regression suite. Actual Store archive and expanded distribution
package contain zero presets and no OpenGL/projectM/Sparkle dependency.

A final rerun exposed an intermittent exact-pixel failure in the zero-Chaos test
for Orbit Loom (320×180, Zoom 3, time 0.801). A retry passed, but a targeted
100-pair diagnostic reproduced one mismatch (493 channels, maximum difference 13).
This remains unresolved; the final regression run is not uniformly clean. The
initial passing evidence and the later failure are both retained locally.

## Direct updates and signing

`macOS/DirectRelease.json` pins Sparkle 2.10.0, its upstream archive SHA-256, the
PulseCanvas-only Ed25519 public key, direct bundle identifier and feed URL.
`prepare-sparkle.py` verifies the downloaded archive before extracting it.
The private update key remains in Keychain account `pulsecanvas-direct`; it is not
part of the repository, source archive or app.

```sh
./scripts/build-direct-release.sh
# Retry signing without rebuilding after a Keychain authorization failure:
./scripts/sign-direct-release.sh
```

The script signs XPC services and updater helpers inside out, then the framework,
projectM library and application with Protomota's Developer ID Application identity.
It uses hardened runtime and timestamps. Do not weaken Keychain ACLs or library
validation to bypass authorization. System profiling is disabled. The updater and
its settings/menu are compiled only into the direct edition.

Before publication, create the DMG, submit it to Apple's notarization service, wait
for an Accepted result, staple and validate the ticket, and assess it with Gatekeeper.
Sign its Sparkle enclosure using the dedicated update key and verify the signature.
Generate a manifest with the real version/build, download/source URLs, byte length
and SHA-256. Publish the matching source archive and appcast with the DMG. A successful
compile or a partial nested signature is not a completed release.

Current direct release status: compiled; signing stopped at the Sparkle framework
with `errSecInternalComponent` after repeated Keychain authorization prompts.
Notarization, installer validation, appcast publication and live download verification
are **not completed**. The prepared website installer page exposes a download only
when it receives a valid notarized-release manifest. Do not publish an unsigned or
unnotarized placeholder as the release.

## Corresponding source and experiments

`scripts/package-store-source.sh` packages the committed version/build/revision,
engine/vendor source, notices, asset manifests and rebuild scripts without local
preferences, bookmarks, signing profiles, keys or export videos. The source snapshot
contains inputs for both editions; the presence of full-library sources in that
archive does not mean they are bundled in the Store binary.

`experiments/metal-studies` contains two standalone creative Metal studies, excluded
from both app builds. These explore procedural spirals and layered waves with local
beat deformation and no external images. They use a synthetic rhythm for validation,
not the app's audio analyzer. They are not a complete Milkdrop interpreter, verified
preset equivalence, a new shipping effect count or a licensing-clearance claim.
