#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
sdk="${1:-xrsimulator}"
[[ "$sdk" == xros || "$sdk" == xrsimulator ]] || { echo 'Usage: scripts/build-visionos.sh [xros|xrsimulator]' >&2; exit 1; }
python3 scripts/generate-vision-project.py
destination='generic/platform=visionOS Simulator'
[[ "$sdk" != xros ]] || destination='generic/platform=visionOS'
xcodebuild -project PulseCanvasVision.xcodeproj -scheme PulseCanvasVision -configuration Release \
  -sdk "$sdk" -destination "$destination" -derivedDataPath ".build/vision-$sdk" \
  CODE_SIGNING_ALLOWED=NO build
