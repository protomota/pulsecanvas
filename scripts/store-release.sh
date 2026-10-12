#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
action="${1:-help}"
out="$PWD/build/app-store"
mkdir -p "$out"
case "$action" in
  test)
    xcodebuild -project PulseCanvas.xcodeproj -scheme PulseCanvas -configuration Release \
      -derivedDataPath .build/store-test PRODUCT_BUNDLE_IDENTIFIER=com.protomota.pulsecanvas.storevalidation \
      CODE_SIGN_IDENTITY="Apple Development" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=22HV69L32T build
    python3 scripts/validate-store-artifact.py --local '.build/store-test/Build/Products/Release/PulseCanvas Studio.app'
    ;;
  archive-unsigned)
    # Engineering reference only. This archive cannot be uploaded or installed as a signed release.
    xcodebuild -project PulseCanvas.xcodeproj -scheme PulseCanvas -configuration Release \
      -derivedDataPath .build/store-archive -archivePath "$out/PulseCanvas-Unsigned.xcarchive" \
      CODE_SIGNING_ALLOWED=NO archive
    ;;
  archive)
    if [[ "${BUNDLE_ID_CONFIRMED:-}" != com.protomota.pulsecanvas ]]; then
      echo 'Verify/register com.protomota.pulsecanvas in team 22HV69L32T, then set BUNDLE_ID_CONFIRMED=com.protomota.pulsecanvas.' >&2
      exit 1
    fi
    # Existing Xcode account/profile required. Do not create credentials implicitly.
    xcodebuild -project PulseCanvas.xcodeproj -scheme PulseCanvas -configuration Release \
      -derivedDataPath .build/store-archive -archivePath "$out/PulseCanvas.xcarchive" archive
    python3 scripts/validate-store-artifact.py --archive "$out/PulseCanvas.xcarchive/Products/Applications/PulseCanvas Studio.app"
    ;;
  export)
    xcodebuild -exportArchive -archivePath "$out/PulseCanvas.xcarchive" \
      -exportOptionsPlist macOS/ExportOptions.plist -exportPath "$out/export"
    ;;
  *)
    echo 'Usage: scripts/store-release.sh test | archive-unsigned | archive | export'
    echo 'Upload with Xcode Organizer: Distribute App → App Store Connect → Upload.'
    echo 'See docs/app-store/README.md for release holds and account setup.'
    ;;
esac
