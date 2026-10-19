#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
sources=(Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/VisualPreset.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift
 scripts/RendererBundle.swift scripts/SurfaceDeterminismSmoke.swift)
if [[ -f Sources/PulseCanvas/NativeEffects.swift ]]; then
 sources+=(Sources/PulseCanvas/NativeEffects.swift)
fi
xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library "${sources[@]}" -o .build/validation/verify-surface-determinism
.build/validation/verify-surface-determinism
