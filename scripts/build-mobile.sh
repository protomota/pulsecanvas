#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
sdk="${1:-iphonesimulator}"
[[ "$sdk" == iphoneos || "$sdk" == iphonesimulator ]] || { echo 'Usage: scripts/build-mobile.sh [iphoneos|iphonesimulator]' >&2; exit 1; }
python3 scripts/generate-mobile-project.py
destination='generic/platform=iOS Simulator'
[[ "$sdk" != iphoneos ]] || destination='generic/platform=iOS'
xcodebuild -project PulseCanvasMobile.xcodeproj -scheme PulseCanvasMobile -configuration Release \
  -sdk "$sdk" -destination "$destination" -derivedDataPath "${PULSECANVAS_DERIVED_DATA:-.build/mobile-$sdk}" \
  CODE_SIGNING_ALLOWED=NO build
