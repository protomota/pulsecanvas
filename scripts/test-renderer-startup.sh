#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -suppress-warnings -swift-version 6 \
  Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/StrobeDetector.swift \
  Sources/PulseCanvas/*Geometry.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/VisualPreset.swift \
  Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift \
  scripts/RendererBundle.swift scripts/RendererStartupSmoke.swift -o .build/validation/verify-renderer-startup
.build/validation/verify-renderer-startup
