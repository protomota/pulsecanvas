#!/bin/bash
# Runs the visionOS UI tests (visionOS/UITests) on a simulator. Every test launches the app with -PCUITesting, which
# uses fresh temporary storage, so the simulator's own PulseCanvas projects are left alone.
#   scripts/test-vision-ui.sh ["Apple Vision Pro" | <simulator UDID>] [extra xcodebuild args, e.g. -only-testing:...]
set -euo pipefail
cd "$(dirname "$0")/.."
device="${1:-Apple Vision Pro}"; shift || true
python3 scripts/generate-vision-project.py >/dev/null
if [[ "$device" =~ ^[0-9A-F-]{36}$ ]]; then destination="platform=visionOS Simulator,id=$device"
else destination="platform=visionOS Simulator,name=$device"; fi
xcodebuild -project PulseCanvasVision.xcodeproj -scheme PulseCanvasVision -configuration Debug \
  -destination "$destination" -derivedDataPath .build/vision-uitests -parallel-testing-enabled NO "$@" test
