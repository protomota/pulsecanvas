#!/bin/bash
# Direct-download edition: release-era numeric indices must never resolve to new native designs.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -O -suppress-warnings -swift-version 6 -parse-as-library \
 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/ProjectMPresets.swift \
 Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/AudioAnalysis.swift \
 Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift \
 scripts/RendererBundle.swift scripts/NativeMigrationSmoke.swift -o .build/validation/verify-native-migration
.build/validation/verify-native-migration
