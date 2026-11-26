#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output='/Volumes/Expand/Codex Media/PulseCanvas Studio/Development/icloud-20261110'
[[ -d /Volumes/Expand ]] || { echo 'Expand is not mounted.' >&2; exit 1; }
mkdir -p "$output/tmp"
export TMPDIR="$output/tmp"
xcrun swiftc -swift-version 6 -parse-as-library \
  Sources/PulseCanvas/CloudSyncLedger.swift Sources/PulseCanvas/CloudProjectPackage.swift \
  Sources/PulseCanvas/UserBackup.swift Sources/PulseCanvas/SecurityScopedAccess.swift \
  scripts/CloudSyncSmoke.swift -o "$output/cloud-sync-smoke"
"$output/cloud-sync-smoke"
