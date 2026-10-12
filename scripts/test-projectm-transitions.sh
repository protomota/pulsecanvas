#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -suppress-warnings -O -swift-version 6 -parse-as-library \
 Sources/PulseCanvas/ProjectMEngine.swift scripts/ProjectMTransitionSmoke.swift \
 -o .build/validation/verify-projectm-transitions
.build/validation/verify-projectm-transitions
