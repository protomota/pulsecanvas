#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
mkdir -p .build/validation
xcrun swiftc -swift-version 6 Sources/PulseCanvas/MeshGeometry.swift scripts/FamilyGeometrySmoke.swift -o .build/validation/family-geometry
.build/validation/family-geometry
