#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
identity="${DEVELOPER_ID_APPLICATION:-Developer ID Application: Protomota, LLC (22HV69L32T)}"
app="${1:-$PWD/build/direct/PulseCanvas Studio.app}"
test -f "$app/Contents/MacOS/PulseCanvas"
# Include the installer artwork before the final app signature.
cp packaging/macos/background.tiff "$app/Contents/Resources/PulseCanvasInstallerBackground.tiff"
# Sign inside out. Preserve framework symlinks and sign every nested executable.
framework="$app/Contents/Frameworks/Sparkle.framework/Versions/B"
while IFS= read -r -d '' bundle; do
  codesign --force --options runtime --timestamp --sign "$identity" "$bundle"
done < <(find "$framework/XPCServices" -name '*.xpc' -type d -print0)
codesign --force --options runtime --timestamp --sign "$identity" "$framework/Autoupdate"
codesign --force --options runtime --timestamp --sign "$identity" "$framework/Updater.app"
codesign --force --options runtime --timestamp --sign "$identity" "$app/Contents/Frameworks/Sparkle.framework"
codesign --force --options runtime --timestamp --sign "$identity" "$app/Contents/Frameworks/libprojectM.dylib"
codesign --force --options runtime --timestamp --sign "$identity" "$app"
codesign --verify --deep --strict --verbose=2 "$app"
python3 scripts/preset-provenance.py --app "$app"
printf 'Developer ID signed app: %s\n' "$app"
