#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -O -whole-module-optimization -swift-version 6 -parse-as-library \
 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/StrobeDetector.swift \
 Sources/PulseCanvas/*Geometry.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift \
 scripts/RendererBundle.swift scripts/OrganicPulseSmoke.swift -o .build/validation/verify-organic-pulse
.build/validation/verify-organic-pulse | tee docs/organic-pulse-validation.log
