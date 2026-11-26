#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/pulsecanvas-audio-tests.XXXXXX")"
trap 'rm -rf "$test_dir"' EXIT
cd "$project_dir"
xcrun swiftc -swift-version 5 -suppress-warnings -parse-as-library \
  "$project_dir/Sources/PulseCanvas/AudioAnalysis.swift" \
  "$project_dir/Sources/PulseCanvas/SecurityScopedAccess.swift" \
  "$project_dir/Sources/PulseCanvas/AudioController.swift" \
  "$project_dir/Sources/PulseCanvas/BundledSoundtrack.swift" \
  "$project_dir/scripts/RendererBundle.swift" \
  "$project_dir/scripts/AudioSmoke.swift" \
  -o "$test_dir/audio-smoke"
"$test_dir/audio-smoke" "$test_dir" "$@"
