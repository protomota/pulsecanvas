#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
./scripts/build-projectm.sh > .build/validation/projectm-build.log 2>&1
xcrun swiftc -suppress-warnings -O -parse-as-library Sources/PulseCanvas/ProjectMEngine.swift scripts/ProjectMErrorStandalone.swift scripts/ProjectMPackSmoke.swift -o .build/validation/verify-projectm-pack
.build/validation/verify-projectm-pack
