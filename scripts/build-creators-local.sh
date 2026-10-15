#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -f .build/projectm/install/lib/libprojectM-4.4.2.0.dylib ]]; then ./scripts/build-projectm.sh; fi
if [[ ! -d .build/sparkle/Sparkle.framework ]]; then python3 scripts/prepare-sparkle.py; fi
python3 scripts/native-visualizer-catalog.py --output Sources/PulseCanvas/Resources/NativeVisualizers.json
app="${1:-$PWD/build/local-testing/PulseCanvas Studio Creators Local.app}"
if [[ -e "$app" ]]; then mv "$app" "$app.previous-$(date +%Y%m%d-%H%M%S)"; fi
mkdir -p "$app/Contents/MacOS" "$app/Contents/Frameworks" "$app/Contents/Resources"
xcrun swiftc -O -swift-version 5 -D DIRECT_BUILD -D LOCAL_BUILD -parse-as-library -target arm64-apple-macos14.0 \
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
import json,plistlib,re,sys
from pathlib import Path
app=Path(sys.argv[1]);settings=dict(re.findall(r'^(\w+) = (.+)$',Path('macOS/Release.xcconfig').read_text(),re.M))
info=plistlib.loads(Path('macOS/Info.plist').read_bytes())
info.update(CFBundleExecutable='PulseCanvas',CFBundleIdentifier='com.protomota.pulsecanvas.creators-local',CFBundleName='PulseCanvas Studio Creators Local',CFBundleDisplayName='PulseCanvas Studio Creators Local',CFBundleShortVersionString=settings['MARKETING_VERSION'],CFBundleVersion=settings['CURRENT_PROJECT_VERSION'],LSMinimumSystemVersion='14.0',PulseCanvasLocalTesting=True,SUEnableAutomaticChecks=False)
for key in ['SUFeedURL','SUPublicEDKey']:info.pop(key,None)
(app/'Contents/Info.plist').write_bytes(plistlib.dumps(info))
PY
# Local-only ad-hoc signing needs no Keychain access or distribution credentials.
codesign --force --deep --sign - "$app"
codesign --verify --deep --strict "$app"
python3 scripts/preset-provenance.py --app "$app"
printf 'Local Creators app: %s\n' "$app"
