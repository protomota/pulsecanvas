#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
common=(Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/VisualPreset.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift scripts/RendererBundle.swift)
xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library "${common[@]}" \
  Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift scripts/StoreEditionSmoke.swift -o .build/validation/verify-store-edition
.build/validation/verify-store-edition
xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library "${common[@]}" scripts/RendererOfflineSmoke.swift -o .build/validation/verify-store-offline
.build/validation/verify-store-offline
xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library "${common[@]}" Sources/PulseCanvas/AudioAnalysis.swift scripts/ChaosSmoke.swift -o .build/validation/verify-store-chaos
.build/validation/verify-store-chaos
nm -u .build/validation/verify-store-edition | python3 -c 'import sys; s=sys.stdin.read(); assert "CGLCreateContext" not in s and "_projectm_" not in s; print("PASS no projectM/OpenGL imports")'
