#!/bin/bash
# Build and run the native effect gallery. Examples:
#   scripts/native-gallery.sh stills --scenes 31-99 --size 640x360 --out .build/gallery/wide
#   scripts/native-gallery.sh frames --scenes 40 --size 480x270 --start 10 --duration 4 --fps 30
#   scripts/native-gallery.sh audit --scenes 0-99 --size 320x180 --duration 2 --fps 60
#   scripts/native-gallery.sh timing --scenes 31-99 --size 3840x2160
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
binary=.build/validation/native-gallery
sources=(Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift
 Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMPresets.swift Sources/PulseCanvas/VisualizerRenderer.swift
 Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/SocialExportController.swift
 Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift scripts/RendererBundle.swift scripts/NativeGallery.swift)
needs_build=0
[ -x "$binary" ] || needs_build=1
for source in "${sources[@]}"; do [ "$source" -nt "$binary" ] && needs_build=1; done
if [ "$needs_build" = 1 ]; then
  xcrun swiftc -O -suppress-warnings -swift-version 6 -D STORE_BUILD -parse-as-library "${sources[@]}" -o "$binary"
fi
"$binary" "$@"
