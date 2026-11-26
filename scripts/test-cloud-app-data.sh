#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output='/Volumes/Expand/Codex Media/PulseCanvas Studio/Development/icloud-20261110'
[[ -d /Volumes/Expand ]] || exit 1
mkdir -p "$output/tmp"
export TMPDIR="$output/tmp"
for mode in creators store; do
  if [[ "$mode" == store ]]; then set -- -D STORE_BUILD; else set --; fi
  xcrun swiftc -swift-version 5 -parse-as-library "$@" \
    Sources/PulseCanvas/SecurityScopedAccess.swift Sources/PulseCanvas/VisualPalette.swift Sources/PulseCanvas/*Geometry.swift \
    Sources/PulseCanvas/StrobeDetector.swift Sources/PulseCanvas/ProjectMEngine.swift Sources/PulseCanvas/VisualPreset.swift Sources/PulseCanvas/ProjectMPresets.swift \
    Sources/PulseCanvas/VisualizerRenderer.swift Sources/PulseCanvas/NativeEffects.swift Sources/PulseCanvas/AudioAnalysis.swift \
    Sources/PulseCanvas/AudioController.swift Sources/PulseCanvas/BundledSoundtrack.swift \
    Sources/PulseCanvas/StudioTimeline.swift Sources/PulseCanvas/StudioStore.swift Sources/PulseCanvas/RadioLibrary.swift Sources/PulseCanvas/RadioController.swift \
    Sources/PulseCanvas/UserBackup.swift Sources/PulseCanvas/CloudSyncLedger.swift Sources/PulseCanvas/CloudProjectPackage.swift Sources/PulseCanvas/CloudSyncAppData.swift Sources/PulseCanvas/CloudSyncService.swift \
    scripts/RendererBundle.swift scripts/CloudSyncAppDataSmoke.swift -o "$output/cloud-app-data-$mode"
  "$output/cloud-app-data-$mode"
done
