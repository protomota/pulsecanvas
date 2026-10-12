#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -O -swift-version 6 -parse-as-library Sources/PulseCanvas/AudioAnalysis.swift Sources/PulseCanvas/StrobeDetector.swift scripts/RhythmSmoke.swift -o .build/validation/verify-rhythm
.build/validation/verify-rhythm "$@" | tee docs/rhythm-validation.log
