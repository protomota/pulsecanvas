#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/curation
xcrun swiftc -O -suppress-warnings -swift-version 5 -parse-as-library \
 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/VisualPreset.swift Sources/PulseCanvas/ProjectMPresets.swift \
 Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/AudioAnalysis.swift \
 Sources/PulseCanvas/SocialExportController.swift Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift \
 scripts/RendererBundle.swift scripts/OpenGLReviewRender.swift -o .build/curation/render-opengl-review
