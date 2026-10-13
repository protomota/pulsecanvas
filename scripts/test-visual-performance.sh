#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -O -whole-module-optimization -swift-version 6 -parse-as-library \
  Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/StrobeDetector.swift \
  Sources/PulseCanvas/*Geometry.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift \
  scripts/RendererBundle.swift scripts/VisualPerformanceSmoke.swift -o .build/validation/verify-performance
.build/validation/verify-performance "$@" | tee docs/visual-performance-validation.log
