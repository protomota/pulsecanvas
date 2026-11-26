#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
# Host the real editor offscreen, without starting its App or opening user windows.
sed '/^@main$/d' Sources/PulseCanvas/PulseCanvasApp.swift > .build/validation/CreatorLayout.swift
sources=()
for source in Sources/PulseCanvas/*.swift; do
  if [[ "$source" != "Sources/PulseCanvas/PulseCanvasApp.swift" ]]; then sources+=("$source"); fi
done
xcrun swiftc -suppress-warnings -swift-version 5 -parse-as-library \
  "${sources[@]}" .build/validation/CreatorLayout.swift scripts/RendererBundle.swift scripts/CompactLayoutSmoke.swift \
  -o .build/validation/verify-compact-layout
.build/validation/verify-compact-layout | tee .build/validation/compact-studio-layout.log
