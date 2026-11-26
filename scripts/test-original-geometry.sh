#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/pulsecanvas-original-geometry.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -swift-version 6 -parse-as-library \
  "$project_dir/Sources/PulseCanvas/VisualPalette.swift" \
  "$project_dir/Sources/PulseCanvas/OriginalGeometry.swift" \
  "$project_dir/scripts/OriginalGeometrySmoke.swift" \
  -o "$test_dir/original-geometry-smoke"
"$test_dir/original-geometry-smoke"
