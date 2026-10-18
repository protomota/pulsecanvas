#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/visionos-validation
xcrun swiftc -O -suppress-warnings -D STORE_BUILD -parse-as-library \
 Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/OriginalGeometry.swift \
 Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/ProjectMPresets.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/VisualizerRenderer.swift \
 Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/StudioTimeline.swift \
 Sources/PulseCanvas/StudioStore.swift Sources/PulseCanvas/SocialExportController.swift \
 Sources/PulseCanvas/SecurityScopedAccess.swift visionOS/VisionProject.swift \
 visionOS/VisionProjectInterchange.swift scripts/RendererBundle.swift \
 scripts/VisionInterchangeExportSmoke.swift -o .build/visionos-validation/verify-interchange-export
.build/visionos-validation/verify-interchange-export
