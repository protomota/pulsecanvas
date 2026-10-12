#!/bin/bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"
mkdir -p .build/validation docs
xcrun swiftc -suppress-warnings -swift-version 6 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift \
  Sources/PulseCanvas/*Geometry.swift \
  Sources/PulseCanvas/StrobeDetector.swift \
  Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift \
  Sources/PulseCanvas/AudioAnalysis.swift \
  Sources/PulseCanvas/SocialExportController.swift \
  Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift scripts/RendererBundle.swift scripts/SocialExportSmoke.swift \
  -o .build/validation/verify-social-export
.build/validation/verify-social-export | tee docs/social-export-validation.log
