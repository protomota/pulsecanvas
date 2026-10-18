#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/visionos-validation
xcrun swiftc -O -parse-as-library visionOS/VisionVideoFile.swift scripts/VisionVideoSaveSmoke.swift \
 -o .build/visionos-validation/verify-video-save
.build/visionos-validation/verify-video-save
