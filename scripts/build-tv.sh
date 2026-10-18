#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
sdk="${1:-appletvsimulator}"
[[ "$sdk" == appletvos || "$sdk" == appletvsimulator ]] || { echo 'Usage: scripts/build-tv.sh [appletvos|appletvsimulator]' >&2; exit 1; }
python3 scripts/generate-tv-project.py
destination='generic/platform=tvOS Simulator'
[[ "$sdk" != appletvos ]] || destination='generic/platform=tvOS'
xcodebuild -project PulseCanvasTV.xcodeproj -scheme PulseCanvasTV -configuration Release \
 -sdk "$sdk" -destination "$destination" -derivedDataPath "${PULSECANVAS_DERIVED_DATA:-.build/tv-$sdk}" \
 CODE_SIGNING_ALLOWED=NO build
