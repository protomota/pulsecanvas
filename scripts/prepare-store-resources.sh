#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-projectm.sh
./scripts/build-shaders.sh
# Recreate generated notices so obsolete application-license copies cannot linger.
rm -rf .build/store-resources/Legal
mkdir -p .build/store-resources/Legal
xcrun swift scripts/build-icon.swift .build/store-resources/AppIcon.iconset
xcrun iconutil -c icns .build/store-resources/AppIcon.iconset -o .build/store-resources/AppIcon.icns
./scripts/prepare-legal-resources.sh .build/store-resources/Legal
