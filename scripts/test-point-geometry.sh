#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
mkdir -p .build/validation
xcrun swiftc -swift-version 6 scripts/reference/PointGeometry.swift scripts/PointGeometrySmoke.swift -o .build/validation/point-geometry
.build/validation/point-geometry
