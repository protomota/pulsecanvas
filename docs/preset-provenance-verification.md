# Attribution and provenance verification — 2026-10-12

Implementation revision: `70b0e479f06811a68cdc38a36dc00dcf28f31be9` on
`codex/preset-attribution-provenance`.

Change link (private, accessible to authorized repository members):
https://github.com/protomota/pulsecanvas/commit/70b0e479f06811a68cdc38a36dc00dcf28f31be9

The repository remains private. No issue reply was posted because there is no
authorized publicly accessible change link for the curator. Issue #8 was re-read
after implementation; it still contained only the curator's existing reply.
A user-approved accessible change artifact is needed before commenting. No
private source, repository visibility, distribution channel or engine architecture
was changed to obtain a public link.

## Inputs and scope

Verified checkout: `/Users/brad/Documents/GIT_SOURCE/pulsecanvas-studio`.
Remote: `git@github.com:protomota/pulsecanvas.git`.
Applicable ancestor AGENTS.md and the user-provided memory were read. There is no
nested project AGENTS.md. Existing task-related uncommitted attribution work was
reviewed and continued. Unrelated `docs/app-store/SUBMISSION-STATUS.md` edits and
untracked marketing/feature-card assets remain unstaged. Production soundtrack,
session, presets and preferences were not replaced by the UI validation build.

Read before editing:

- Preset README and LICENSE at `0180df21f5e0bd39b9060cc5de420ed2f1f9e509`.
- Issue #8, including the curator's reply confirming the exact ISOSCELES credit.
- Official projectM licensing wiki, including Apple Store Compatibility.
- Texture README on master; bundled images verified against pinned commit
  `6368812f27bc747b517218fbf89d21d59afce4d9`.

## Implemented files

- `Sources/PulseCanvas/PulseCanvasApp.swift`: accessible Legal & Credits window,
  app-menu entry and Help entry with the exact credit and clickable Patreon link.
- `Sources/PulseCanvas/Resources/ProjectM/Preset-README.md`: unchanged upstream
  README bytes; existing `Preset-notice.md` remains unchanged LICENSE bytes.
- `Sources/PulseCanvas/Resources/ProjectM/Provenance.md`: independent application,
  engine, preset and texture terms and unresolved Apple distribution warning.
- `Sources/PulseCanvas/Resources/ProjectM/preset-manifest.json`: original paths,
  hashes, stable IDs, original creator/title metadata and display-name mapping.
- `Sources/PulseCanvas/Resources/ProjectM/preset-notices.json`: every-file scan
  with line-numbered candidates, without inferred license classifications.
- `Sources/PulseCanvas/Resources/ProjectM/texture-manifest.json`: independent
  original-image inventory, upstream pin, paths and hashes.
- `scripts/preset-provenance.py` and `scripts/test-preset-provenance.py`:
  generation from pinned Git objects; exact-subset, hash, notice, catalog,
  archive-safety, app-resource and committed source-package checks.
- `scripts/prepare-legal-resources.sh`, `scripts/prepare-store-resources.sh`,
  `scripts/build-app.sh` and `scripts/validate-store-artifact.py`: both build
  routes retain legal notices/manifests; portable version follows release config.
- `scripts/package-store-source.sh`: immutable version/build/revision filename,
  fresh staging and full committed-file comparison.
- `README.md`, `third_party/PROJECTM.md`, `docs/licensing.md`,
  `docs/app-store/LICENSES.md`, `docs/app-store/RIGHTS-RESOLUTION.md` and
  `docs/app-store/README.md`: credit and provenance guidance, separate unresolved
  asset permissions and upstream Apple-store release blocker.
- `macOS/Release.xcconfig`: requested prepared version **1.0.2 (9)**.

No preset, texture, catalog identity, original filename or embedded notice bytes
were rewritten. Current first-party code retains the Source-Available
Noncommercial License; this update does not relicense dependencies or assets.

## Passed verification

| Check | Result |
|---|---|
| Pinned upstream Git-object comparison | All 7,838 bundled .milk files byte-identical at their original paths; upstream tree has 9,795 .milk files |
| Independent texture comparison | 67 original images plus unchanged upstream README, all byte-identical at the texture pin |
| Catalog mapping | 7,838 unique stable IDs/paths; retained original titles and deterministic mapping to current display titles |
| Every-file notice scan | 7,838 scanned; 284 candidate lines in 141 files; entire original file hashes preserve unmatched comments as well |
| Notice preservation | Pinned preset README/LICENSE, texture README, engine LGPL and vendor licenses/full embedded image-loader source notices retained |
| Provenance regression tests | 9 passed, including missing/extra/modified assets, duplicate paths, symlinks, legacy bytes, line numbers and unsafe archive rejection |
| Creator engagement tests | Portable and STORE_BUILD modes passed; second successful export behavior unchanged |
| ProjectM integration test | Library identities/favorites/imports, GPU rendering and shared surfaces passed; decoded portrait Studio export and consecutive 4K/60 preset-switch exports passed |
| Signed 1.0.2 (9) Xcode archive | Passed; arm64/macOS 14+, hardened runtime, sandbox and same-team nested engine signing |
| Installer export/signature | Export succeeded; installer signature validated |
| Actual exported app inspection | Full preset/texture inventory and hashes, catalog/manifest copies, Legal resources, vendor notices, privacy/entitlements, app license and version/build passed |
| Live isolated validation app | App-menu Legal & Credits opens; exact credit and clickable link present in accessibility tree; notice-folder action opens this build's actual Legal directory |
| Exact engine-source snapshot | 925 source files match unchanged archive; 989 AppleDouble metadata entries skipped; engine source SHA-256 retained |
| Matching source archive inspection | Full committed-file set and bytes match implementation revision; subset/manifests/notices/version/build and engine source/rebuild inputs passed |
| Clean source-archive rebuild | Extracted archive rebuilt engine, shaders and Swift app successfully without the checkout's build cache; resulting portable app passed resource provenance checks |
| Portable checkout build | Passed, including provenance checks |
| Diff whitespace validation | Passed |

The initial raw engine comparison encountered a missing AppleDouble metadata
entry. The corrected comparison explicitly excluded those non-source entries;
all 925 actual source files matched. No unresolved test failure remains. Existing
OpenGL deprecation warnings remain; passing engineering checks does not establish
asset permission or distribution compatibility.

The exhaustive 7,838-preset aesthetic/performance GPU sweep was **not rerun**:
rendering code and original preset bytes were unchanged. Relevant integration
render/export tests were run. Upload processing, TestFlight installation and
public source-download checks were **not run** because no new upload/publication
was attempted in this update.

## Local artifacts

- Archive: `build/app-store/PulseCanvas-1.0.2-9.xcarchive`.
- Installer: `build/app-store/export-1.0.2-9/PulseCanvas Studio.pkg`.
- Matching source: `build/app-store/PulseCanvas-1.0.2-9-70b0e479f068-source.tar.gz`.
- Source SHA-256: `87b5da48ce6bb855770269c24a3cf392f6f9d3751e34e47fa2455d0c73744ed0`.
- Engine source SHA-256: `310d17c30590fe1700cb730f6237323f7eafed29adc1a3c85c6567d5fc18cf5c`.
- Logs, checksums, JSON receipt and screenshots: `work/preset-provenance/`.

These are local preparation artifacts, not publicly available source downloads.
Older version-matched archives were not overwritten or relabeled.

## Apple status and remaining blockers

At the owner's request, existing build **1.0.1 (8)** was withdrawn from App Review.
The submission detail page confirms **Removed** for submission
`fc05a326-a9bf-4313-80ea-66ff81f8464f`:
https://appstoreconnect.apple.com/apps/6821642700/distribution/reviewsubmissions/details/fc05a326-a9bf-4313-80ea-66ff81f8464f

Prepared **1.0.2 (9)** has not been uploaded, assigned to TestFlight or submitted
for review. The owner's original attribution request prohibited submission and
required recording the upstream warning; the subsequent upload request is being
clarified specifically for internal testing. No public release was requested or
performed. Existing TestFlight builds/testers were not expired or changed.

Unresolved blockers remain separate:

1. Official projectM guidance explicitly warns against Apple-store distribution,
   including macOS. Dynamic linking, wrapper licensing and corresponding source
   do not resolve it. No claim of legal clearance is made.
2. Individual preset permissions remain unresolved; curator credit and historical
   community practice do not supply documented author grants.
3. Texture permissions remain independently unresolved.
4. Existing PVRTC vendor-provenance and public corresponding-source work remains
   unresolved. Engine snapshot and rebuild/relink work are preserved.
5. No safe publicly accessible change link is available for the curator reply.

Primary references are recorded in the packaged Provenance.md and
docs/app-store/RIGHTS-RESOLUTION.md. Issue #8 remains open; no email was sent.
