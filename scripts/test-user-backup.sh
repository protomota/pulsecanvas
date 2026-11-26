#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output='/Volumes/Expand/Codex Media/PulseCanvas Studio/Development/user-backup-20261110'
[[ -d '/Volumes/Expand' ]] || { echo 'Expand is not mounted.' >&2; exit 1; }
mkdir -p "$output/tmp"
export TMPDIR="$output/tmp"
package="$output/SmokePackage"
mkdir -p "$package/Sources/BackupSmoke"
cat > "$package/Package.swift" <<'SWIFT'
// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "BackupSmoke", platforms: [.macOS(.v14)],
    dependencies: [.package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20")],
    targets: [.executableTarget(name: "BackupSmoke", dependencies: ["ZIPFoundation"])])
SWIFT
for source in Sources/PulseCanvas/UserBackup.swift Sources/PulseCanvas/UserBackupZIP.swift Sources/PulseCanvas/SecurityScopedAccess.swift scripts/UserBackupSmoke.swift; do
    ln -sf "$PWD/$source" "$package/Sources/BackupSmoke/$(basename "$source")"
done
swift run --package-path "$package" BackupSmoke
