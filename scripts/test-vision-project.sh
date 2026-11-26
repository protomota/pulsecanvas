#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/visionos-validation
xcrun swiftc -O -parse-as-library Sources/PulseCanvas/VisualPalette.swift \
 Sources/PulseCanvas/OriginalGeometry.swift Sources/PulseCanvas/NativeEffects.swift \
 Sources/PulseCanvas/StudioTimeline.swift visionOS/VisionProject.swift \
 scripts/VisionProjectSmoke.swift -o .build/visionos-validation/verify-project
.build/visionos-validation/verify-project
