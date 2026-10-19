#!/bin/bash
# Export a motion reel through the Studio exporter, then burn in effect names.
#   scripts/native-reel.sh --scenes 31-99 --seconds 3 --start 20 --aspect wide --resolution 720 --fps 30 --out .build/reels/new.mp4
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
binary=.build/validation/native-reel
sources=(Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/VisualPreset.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift
 Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/SocialExportController.swift
 Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift scripts/RendererBundle.swift scripts/NativeReel.swift)
needs_build=0
[ -x "$binary" ] || needs_build=1
for source in "${sources[@]}"; do [ "$source" -nt "$binary" ] && needs_build=1; done
if [ "$needs_build" = 1 ]; then
  xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library "${sources[@]}" -o "$binary"
fi
"$binary" "$@"
output=$(printf '%s\n' "$@" | awk 'previous == "--out" { print } { previous = $0 }')
output=${output:-.build/reels/reel.mp4}
python3 scripts/label-reel.py "$output"
