#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -Onone -g -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library \
 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift \
 Sources/PulseCanvas/OriginalGeometry.swift Sources/PulseCanvas/NativeEffects.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/VisualPreset.swift Sources/PulseCanvas/ProjectMPresets.swift \
 Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/AudioAnalysis.swift \
 Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift \
 Sources/PulseCanvas/RadioLibrary.swift scripts/RendererBundle.swift scripts/VisualizerPoolSmoke.swift \
 -o .build/validation/verify-visualizer-pool
.build/validation/verify-visualizer-pool
