#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -suppress-warnings -swift-version 5 -suppress-warnings -parse-as-library \
  Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/AudioController.swift \
  Sources/PulseCanvas/BundledSoundtrack.swift \
  Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
  Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/VisualPreset.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift \
  scripts/RendererBundle.swift scripts/AudioSyncSmoke.swift -o .build/validation/verify-audio-sync
.build/validation/verify-audio-sync "$@" | tee docs/audio-sync-validation.log
