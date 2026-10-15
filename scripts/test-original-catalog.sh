#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library \
 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift \
 Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/SocialExportController.swift \
 Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift scripts/RendererBundle.swift \
 scripts/OriginalCatalogSmoke.swift -o .build/validation/verify-original-catalog
.build/validation/verify-original-catalog
