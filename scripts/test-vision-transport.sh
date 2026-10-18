#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/visionos-validation
xcrun swiftc -O -suppress-warnings -D STORE_BUILD -parse-as-library \
 Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/OriginalGeometry.swift \
 Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/ProjectMPresets.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/VisualizerRenderer.swift \
 Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/RadioLibrary.swift \
 visionOS/VisionProject.swift visionOS/VisionStudio.swift visionOS/VisionSession.swift scripts/RendererBundle.swift \
 scripts/VisionTransportSmoke.swift -o .build/visionos-validation/verify-transport
.build/visionos-validation/verify-transport
