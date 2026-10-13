#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
mkdir -p .build/validation
xcrun swiftc -suppress-warnings -swift-version 6 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/*Geometry.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift scripts/RendererBundle.swift scripts/RendererOfflineSmoke.swift -o .build/validation/verify-offline-renderer
.build/validation/verify-offline-renderer
