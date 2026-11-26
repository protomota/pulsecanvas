#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -swift-version 6 -parse-as-library Sources/PulseCanvas/StrobeDetector.swift scripts/StrobeSmoke.swift -o .build/validation/strobe-smoke
.build/validation/strobe-smoke
