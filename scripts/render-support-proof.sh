#!/bin/bash
# Test-only: render the Mac Settings support rows and Settings support card to PNGs offscreen.
#   scripts/render-support-proof.sh OUTPUT_DIR
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:?Usage: scripts/render-support-proof.sh OUTPUT_DIR}"
mkdir -p .build/validation "$output"
[[ -f .build/AppIcon.iconset/icon_512x512@2x.png ]] || xcrun swift scripts/build-icon.swift .build/AppIcon.iconset
xcrun swiftc -swift-version 5 -parse-as-library -D DIRECT_BUILD \
    Sources/PulseCanvas/CreatorEngagement.swift Sources/PulseCanvas/CreatorThanksView.swift \
    Sources/PulseCanvas/StudioControls.swift scripts/SupportProofRender.swift \
    -o .build/validation/render-support-proof
.build/validation/render-support-proof "$output"
