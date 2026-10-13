#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
identity="${DEVELOPER_ID_APPLICATION:-Developer ID Application: Protomota, LLC (22HV69L32T)}"
python3 scripts/prepare-sparkle.py
./scripts/build-projectm.sh
app="$PWD/build/direct/PulseCanvas Studio.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Frameworks" "$app/Contents/Resources"
xcrun swiftc -O -swift-version 5 -D DIRECT_BUILD -parse-as-library -target arm64-apple-macos14.0 \
  -F .build/sparkle -framework Sparkle -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
  Sources/PulseCanvas/*.swift macOS/BundleResources.swift -o "$app/Contents/MacOS/PulseCanvas"
ditto .build/sparkle/Sparkle.framework "$app/Contents/Frameworks/Sparkle.framework"
cp .build/projectm/install/lib/libprojectM-4.4.2.0.dylib "$app/Contents/Frameworks/libprojectM.dylib"
install_name_tool -id @rpath/libprojectM.dylib "$app/Contents/Frameworks/libprojectM.dylib"
ditto Sources/PulseCanvas/Resources "$app/Contents/Resources/Resources"
./scripts/prepare-legal-resources.sh "$app/Contents/Resources/Legal"
cp .build/sparkle/LICENSE "$app/Contents/Resources/Legal/Sparkle-LICENSE.txt"
cp macOS/PrivacyInfo.xcprivacy "$app/Contents/Resources/PrivacyInfo.xcprivacy"
xcrun swift scripts/build-icon.swift .build/AppIcon.iconset
xcrun iconutil -c icns .build/AppIcon.iconset -o "$app/Contents/Resources/AppIcon.icns"
python3 - "$app" <<'PY'
import json, plistlib, re, sys
from pathlib import Path
app = Path(sys.argv[1]); config = json.loads(Path('macOS/DirectRelease.json').read_text())
settings = dict(re.findall(r'^(\w+) = (.+)$', Path('macOS/Release.xcconfig').read_text(), re.M))
info = plistlib.loads(Path('macOS/Info.plist').read_bytes())
info.update(CFBundleExecutable='PulseCanvas', CFBundleIdentifier=config['bundleIdentifier'],
            CFBundleShortVersionString=settings['MARKETING_VERSION'], CFBundleVersion=settings['CURRENT_PROJECT_VERSION'],
            LSMinimumSystemVersion='14.0', SUFeedURL=config['feedURL'], SUPublicEDKey=config['sparklePublicKey'],
            SUSendsSystemProfile=False, SUEnableAutomaticChecks=True, SUAutomaticallyUpdate=False)
(app / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
PY
./scripts/sign-direct-release.sh "$app"
