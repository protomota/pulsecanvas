#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
xcrun swiftc -suppress-warnings -O -parse-as-library Sources/PulseCanvas/ProjectMEngine.swift scripts/ProjectMErrorStandalone.swift scripts/ProjectMCompositorSmoke.swift -o .build/validation/verify-projectm-compositor
.build/validation/verify-projectm-compositor
