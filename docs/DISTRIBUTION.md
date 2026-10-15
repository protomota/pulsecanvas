## Creators 1.1.2 (19) — update indicator released

Published on 2026-10-15 at https://pulsecanvas.si/download/. Creators now shows a
round download icon beside Random visualizer when Sparkle finds a newer release.
The icon opens the existing Sparkle installer; Remind Me Later retains it and Skip
This Version hides it. Automatic-check preferences remain respected.

Developer ID signing, Apple notarization, stapling, Gatekeeper and the pinned
Sparkle Ed25519 signature all passed. The public DMG and matching source archive
were verified with full download checksums. The deployed website's 77 files were
verified; only its release manifest, appcast and download release notes changed.
An isolated QA app detected the real published 1.1.2 update, displayed the button
and opened Sparkle's update dialog without installing it or changing the user's
session. This release retains 270 native designs, 7,758 community presets and 67
textures. Source revision: `6a661aac2e28d848ff70e3719c1cd2f8ce78ae66`.

DMG SHA-256: `8036fa82160b7fc9a6c692c8b57927aa4959f2d39033e87f4149141ca424ac7d`.
Matching source SHA-256: `a03d5a5d7a3af609a17e0ec9bd6db0c72bb0e3ae9f10fd1c26c386a027f21ae6`.

The update UI and Sparkle remain excluded from the Store edition. No new Store
upload or App Review submission was made for this Creators-only release.

## TestFlight 1.1.1 (18) tester access corrected — 2026-10-15

Build 18 completed upload/processing but had no assigned tester group. It is now assigned to **PulseCanvas Mac Beta**, and the group's build list is verified as **Testing**. Its build ID is `8ee4fe88-6ac3-42d0-aae8-eb3571c06349`. No App Review submission was changed. Future uploads must verify group assignment after processing; an upload alone is not a completed TestFlight release.

## Build 1.1.0 (17) published to website and TestFlight — 2026-10-15

Main is fast-forwarded to `1114115732434abcfd266b053c5b999b3d604647`, preserving local Radio, favorites and curation changes. The latest tunnel-twist and element-level beat motion is verified byte-for-byte in the Store archive, exported installer and Creators app. Both editions contain 270 active native effects; Creators retains 7,758 community presets and 67 textures.

Apple processing completed and build 17 is **Testing** in the internal PulseCanvas Mac Beta group; testing notes are saved. No App Review submission was made. The stopped build 16 was not added to the group and was not published to the website.

Creators 1.1.0 (17) is signed, Apple-notarized, stapled, Gatekeeper-accepted and verified against the pinned Sparkle key. The website installer, matching source, release notes and signed feed are live. All 97 deployed file hashes and all 8,167 source archive files match the frozen release inputs. Older downloads and unrelated unpublished website edits are preserved.

Store/native checks passed for all 270 effects, including music response, deterministic seeking, zero Chaos and 1,620 offline rendering checks. Radio regression and all 15 live songs passed. Preset hashes, texture hashes, original notices and package provenance passed. Existing third-party licensing uncertainties remain unchanged.

- Download: https://pulsecanvas.si/download/
- Installer: https://pulsecanvas.si/downloads/PulseCanvas-Studio-1.1.0-17.dmg
- Matching source: https://pulsecanvas.si/downloads/PulseCanvas-Creators-1.1.0-17-source.tar.gz
- Receipt: `.build/release-1.1.0-17/release-receipt.json`

The release was built from a frozen working-source snapshot before its follow-up Git commit. The version-matched archive preserves every build input; the completed app work is now published to GitHub main. Earlier dated distribution entries below are historical.

## Apple submission withdrawn at owner request — 2026-10-14

App Store 1.1.0 (15) was withdrawn after the owner clarified they were not ready to submit. Apple confirms submission `ffaffc6b-8c07-40c3-b645-4ed8d7000c1b` is **Removed** and version 1.1.0 is **Developer Rejected**. The uploaded build and listing remain available for later preparation. Do not resubmit without explicit owner approval. The website release is unchanged.

The submission status in earlier dated entries below is historical.

## Version 1.1.0 (15) released to website and submitted to Apple — 2026-10-14

Creators 1.1.0 (15) is live at https://pulsecanvas.si/download/. App Store 1.1.0 (15) is **Waiting for Review**, with automatic release after approval. Apple submission: https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/ffaffc6b-8c07-40c3-b645-4ed8d7000c1b . This is not an App Review approval claim.

Includes Radio with a public JSON station directory, all 15 tracks, favorites-first visualizer shuffle, beat-aligned bars, current-visual randomization, full-screen presentation, remembered volume defaulting to 70%, close-to-quit behavior, safe title-bar controls, and unique Studio timeline shuffles. Both editions contain 270 native effects; Creators also contains 7,758 community presets and 67 textures. Radio catalogs and songs are downloaded from https://radio.pulsecanvas.si; user files are not uploaded. The published privacy policy explains these requests.

Store archive/expanded installer signatures, native-only resources and sandbox/network entitlements passed. Creators signing, Accepted notarization, stapling, Gatekeeper and pinned Sparkle signature passed. Radio's 15 live tracks and the 270-visual Store suite passed. All 8,145 source files and all 95 deployed website file hashes were verified. Matching source, new installer and signed appcast are published; old releases remain available. Unrelated unpublished website edits were excluded. No Git commit or push was made.

- Installer: https://pulsecanvas.si/downloads/PulseCanvas-Studio-1.1.0-15.dmg
- Matching source: https://pulsecanvas.si/downloads/PulseCanvas-Creators-1.1.0-15-source.tar.gz
- Update feed: https://pulsecanvas.si/appcast.xml
- Local receipt: `.build/release-1.1.0-15/release-receipt.json`

Older dated status entries below are historical.

# PulseCanvas editions and release checks

## Creators website release — 2026-10-13

Creators **1.0.4 (14)** is published at https://pulsecanvas.si/download/, with 240 approved native Metal effects, 7,838 original community presets and 67 textures. Its full styled support screen is eligible after the second successful save, repeats on later saves until all available buttons have been clicked, and remembers individual clicks locally. Reset saved clicks clears those marks without changing projects, audio, favorites or Apple review history. Multiple editor windows count a completed export once.

Developer ID signing, Apple Accepted notarization, stapling, Gatekeeper acceptance and the Sparkle signature passed. App/source provenance checks, projectM playback/transitions/full-screen mapping and mixed 4K60 export passed. The complete matching source archive contains 8,146 verified files. All 91 deployed website file hashes match the prepared release; the live page shows version/build and the matching source link. Chrome blocked the completed-download test under its organization policy; no policy was changed. This is not a claim of a successful browser download.

- Installer: https://pulsecanvas.si/downloads/PulseCanvas-Studio-1.0.4-14.dmg
- Matching source: https://pulsecanvas.si/downloads/PulseCanvas-Creators-1.0.4-14-source.tar.gz
- Signed update feed: https://pulsecanvas.si/appcast.xml
- Installer SHA-256: `7dad964da366cbbdee45c46e90132a03953ce0f16904fb60593e882a32122631`

Only release metadata, the feed and the two new versioned artifacts changed on the website. Existing site files and older release assets are retained. Unrelated unpublished website edits and the active visualizer worktree are excluded. The source comes from a frozen uncommitted main snapshot; version/build overrides apply only to this Creators snapshot. App Store 1.0.3 (13), its draft and main's Store configuration are unchanged. No Git commit or push was made. Existing engine/asset licensing uncertainties remain separate and unresolved.

The local receipt and build evidence are in `.build/creators-release-1.0.4-14/release-receipt.json`.

## Completed integration on main — 2026-10-13

The main development source contains 240 owner-reviewed native Metal effects in 360 permanent slots. The 120 withdrawn IDs remain reserved. The active new-claude-visualizers worktree remains intact and its ongoing edits are excluded. The 59 newly approved effects come from the frozen review-video source. See [MAIN-INTEGRATION.md](MAIN-INTEGRATION.md).

The Store artifact excludes projectM, its presets/textures and Sparkle. Current Creators source retains 7,758 original presets, 67 textures, notices, manifests and engine-source/rebuild work. Published Creators 1.0.3 (11) and TestFlight 1.0.3 (12) contain the 181 reviewed native selections. Build 12 completed Apple processing and is Testing in PulseCanvas Mac Beta. The next requested TestFlight artifact is 1.0.3 (13), with 240 approved native effects; its upload status is recorded in the release receipt.

The older dated release sections below are historical.


## Version 1.0.2 (10), checked 2026-10-12

| Edition | Build | Resources | Update channel |
| --- | --- | --- | --- |
| Mac App Store | `STORE_BUILD`, generated Xcode project | 31 native Metal visualizers, native palettes/icons, demo MP3 and application license; no projectM, `.milk` presets or external textures | Apple |
| Direct download | `DIRECT_BUILD`, `scripts/build-direct-release.sh` | Native library plus 7,758 retained presets, 67 textures and their unchanged provenance/notices; projectM shared library | Sparkle 2.10.0 |
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

## Local OpenGL curation — 2026-10-14

Current source now contains 7,800 OpenGL presets after the completed first review batch retained 62 red-labelled effects and removed 38 rejected effects. Published 1.0.4 (14) still has its original 7,838 presets; no release was uploaded for this curation. The retirement records preserve saved-project identity migration, and pinned bytes, original creator metadata and notices remain intact for all retained presets. `preset-curation.json` anchors the new count to the completed review. Batch 002 uses the unchanged original review snapshot so its catalog positions stay consistent.

Completed OpenGL Batch 002 on 2026-10-14: kept 78 picks and withdrew 22 unselected presets. Current source/local testing library is 7,778 OpenGL presets; published website builds retain their original inventory. The curation partition, preset hashes and full notice scan were updated, and saved-project migration records retained. Batch 003 uses the original frozen catalog cursor.

Completed OpenGL Batch 003 on 2026-10-14: kept 80 picks and withdrew 20 unselected presets. Current source/local library has 7,758 OpenGL effects. Preset provenance, notices and retirement migration records are updated; website builds remain unchanged. Batch 004 uses the original frozen catalog cursor.
