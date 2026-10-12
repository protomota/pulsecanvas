#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/point-geometry-tests.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -swift-version 6 -parse-as-library \
  "$project_dir/Sources/PulseCanvas/SurfaceGeometry.swift" \
  "$project_dir/scripts/reference/FormulaGeometry.swift" \
  "$project_dir/scripts/GeometrySmoke.swift" \
  -o "$test_dir/geometry-smoke"
"$test_dir/geometry-smoke" "$@"
