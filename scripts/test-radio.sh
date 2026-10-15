#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -O -suppress-warnings -swift-version 5 -D STORE_BUILD -parse-as-library \
  Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
  Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/ProjectMPresets.swift \
  Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift \
  Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/AudioController.swift Sources/PulseCanvas/BundledSoundtrack.swift \
  Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift \
  Sources/PulseCanvas/RadioLibrary.swift Sources/PulseCanvas/RadioController.swift \
  scripts/RendererBundle.swift scripts/RadioSmoke.swift -o .build/validation/verify-radio
.build/validation/verify-radio "$@"
