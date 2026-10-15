#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app="${1:-}"
# The validation suite runs every test without arguments; this one inspects a built app.
[[ -n "$app" ]] || { echo 'SKIP: pass a built PulseCanvas Studio.app to inspect (Usage: test-original-bundle.sh APP)'; exit 0; }
app="$(cd "$app" && pwd)"
python3 scripts/verify-original-resources.py "$app"
mkdir -p .build/validation
xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library \
 Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift \
 Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/StudioTimeline.swift \
 Sources/PulseCanvas/StudioStore.swift scripts/OriginalBundleSmoke.swift -o .build/validation/verify-original-bundle
binary="$PWD/.build/validation/verify-original-bundle"
scratch="$(mktemp -d /tmp/pulsecanvas-bundle-test.XXXXXX)"
trap 'rm -rf "$scratch"' EXIT
cd "$scratch"
PULSECANVAS_TEST_APP="$app" "$binary"
