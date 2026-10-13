#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Never package local preferences, bookmarks, profiles, signing keys or export videos.
mkdir -p .build/store-source build/app-store
staging_root="$(mktemp -d .build/store-source/package.XXXXXX)"
trap 'rm -rf "$staging_root"' EXIT
stage="$staging_root/PulseCanvas-source"
mkdir -p "$stage"
# Package only committed release sources; omit unrelated in-progress assets.
git archive HEAD Sources scripts macOS PulseCanvas.xcodeproj third_party assets Package.swift LICENSE README.md docs/licensing.md docs/app-store docs/unused-code-audit.md docs/DISTRIBUTION.md | tar -x -C "$stage"
# Remove generated Python caches if local checks created them.
find "$stage/scripts" -type d -name __pycache__ -prune -exec rm -rf {} +
release_version="$(awk '/^MARKETING_VERSION = / {print $3}' "$stage/macOS/Release.xcconfig")"
release_build="$(awk '/^CURRENT_PROJECT_VERSION = / {print $3}' "$stage/macOS/Release.xcconfig")"
revision="$(git rev-parse HEAD)"
# Do not overwrite a source archive previously matched to a submitted build.
archive="build/app-store/PulseCanvas-${release_version}-${release_build}-${revision:0:12}-source.tar.gz"
cat > "$stage/BUILD.txt" <<'TXT'
PulseCanvas Studio release source. Version/build are recorded in macOS/Release.xcconfig.
Apple silicon, macOS 14+, Xcode 27.0, CMake required.
Read LICENSE and docs/app-store/LICENSES.md. Individual assets retain their terms.
Read Sources/PulseCanvas/Resources/ProjectM/Provenance.md for the ISOSCELES credit,
upstream pins, preset/texture manifests and unresolved permissions/store blocker.
The Store edition excludes projectM, its presets/textures and Sparkle.
For the full direct edition, run scripts/build-projectm.sh to extract/rebuild the exact bundled engine and vendor source.
Run scripts/store-release.sh test to rebuild/relink a local sandboxed app with your own Apple Development identity.
Run scripts/build-app.sh for the existing portable development workflow.
Run scripts/build-direct-release.sh for the Sparkle direct edition with your own Developer ID identity.
See docs/DISTRIBUTION.md for edition resources, update signing and notarization requirements.
Changing ProjectM source under .build/projectm/source and rebuilding replaces the shared library.
Resign the entire local build including the nested library; do not disable library validation.
This source snapshot is preparation evidence, not a claim of cleared asset rights or live distribution.
TXT
printf '%s\n' "$revision" > "$stage/REVISION.txt"
python3 "$stage/scripts/preset-provenance.py"
COPYFILE_DISABLE=1 tar -czf "$archive" -C "$staging_root" PulseCanvas-source
python3 scripts/preset-provenance.py --source "$archive" --revision "$revision"
shasum -a 256 third_party/projectm-source.tar.gz "$archive" > "build/app-store/source-${release_version}-${release_build}-${revision:0:12}-SHA256.txt"
printf 'Verified source archive: %s\n' "$archive"
