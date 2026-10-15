#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build-projectm.sh
swift build -c release
APP="build/PulseCanvas Studio.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# Remove stale payloads when rebuilding a previously full-library bundle.
rm -f "$APP/Contents/Frameworks/libprojectM.dylib" "$APP/Contents/Resources/Third-Party-Notices.md"
rm -rf "$APP/Contents/Resources/Legal"
cp .build/release/PulseCanvas "$APP/Contents/MacOS/PulseCanvas"
find "$APP/Contents/Resources" -maxdepth 1 -name "*.bundle" -type d -exec rm -rf {} +
cp -R .build/release/PulseCanvas_PulseCanvas.bundle "$APP/Contents/Resources/"
rm -f "$APP/Contents/Resources/PulseCanvas-MIT-LICENSE.txt"
cp LICENSE "$APP/Contents/Resources/PulseCanvas-LICENSE.txt"
./scripts/prepare-legal-resources.sh "$APP/Contents/Resources/Legal"
release_version="$(awk '/^MARKETING_VERSION = / {print $3}' macOS/Release.xcconfig)"
release_build="$(awk '/^CURRENT_PROJECT_VERSION = / {print $3}' macOS/Release.xcconfig)"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>PulseCanvas</string>
<key>CFBundleIdentifier</key><string>com.protomota.pulsecanvas</string>
<key>CFBundleName</key><string>PulseCanvas Studio</string>
<key>CFBundleDisplayName</key><string>PulseCanvas Studio</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$release_version</string>
<key>CFBundleVersion</key><string>$release_build</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
xcrun swift scripts/build-icon.swift .build/AppIcon.iconset
xcrun iconutil -c icns .build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
codesign --force --deep --sign - "$APP"
python3 scripts/verify-original-resources.py "$APP"
printf 'Built %s\n' "$PWD/$APP"
