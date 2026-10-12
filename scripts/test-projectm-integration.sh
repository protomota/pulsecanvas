#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -suppress-warnings -O -swift-version 6 -parse-as-library \
 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift \
 Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/SocialExportController.swift \
 Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift \
 scripts/RendererBundle.swift scripts/ProjectMIntegrationSmoke.swift -o .build/validation/verify-projectm-integration
.build/validation/verify-projectm-integration
