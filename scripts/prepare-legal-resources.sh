#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
legal="${1:?Usage: prepare-legal-resources.sh OUTPUT_DIRECTORY}"
python3 scripts/preset-provenance.py
mkdir -p "$legal"
rm -f "$legal/PulseCanvas-MIT-LICENSE.txt"
cp LICENSE "$legal/PulseCanvas-LICENSE.txt"
cp third_party/PROJECTM.md "$legal/Third-Party-Notices.md"
cp .build/projectm/source/LICENSE.txt "$legal/ProjectM-LGPL-2.1.txt"
cp .build/projectm/source/vendor/hlslparser/LICENSE "$legal/hlslparser-MIT.txt"
cp .build/projectm/source/vendor/projectm-eval/LICENSE.md "$legal/projectm-eval-MIT.txt"
# Retain complete embedded notices, including each image-loader extension.
cp .build/projectm/source/vendor/stb_image/*.[ch] "$legal/"
for name in Preset-README.md Preset-notice.md Provenance.md preset-manifest.json preset-notices.json texture-manifest.json; do
    cp "Sources/PulseCanvas/Resources/ProjectM/$name" "$legal/"
done
cp Sources/PulseCanvas/Resources/ProjectM/Textures/README.md "$legal/Texture-provenance.md"
