#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/visionos-validation
xcrun swiftc -O -parse-as-library visionOS/VisionPresentation.swift \
 scripts/VisionPresentationSmoke.swift -o .build/visionos-validation/verify-presentation
.build/visionos-validation/verify-presentation
