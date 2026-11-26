#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_root="$PWD/.build/updater-smoke"
mkdir -p "$test_root/feed"
python3 - "$test_root" <<'PY'
from pathlib import Path
import json, plistlib, sys, uuid
root = Path(sys.argv[1])
config = json.loads(Path('macOS/DirectRelease.json').read_text())
for name, build, enabled, expected in [('available', '1', True, '2.0'), ('current', '999999', True, None), ('disabled', '1', False, None)]:
    app = root / (name + '.app')
    (app / 'Contents/MacOS').mkdir(parents=True, exist_ok=True)
    info = dict(CFBundleIdentifier='com.protomota.pulsecanvas.updater-test.' + name + '.' + uuid.uuid4().hex,
                CFBundleExecutable='UpdaterSmoke', CFBundleName='Updater Test', CFBundlePackageType='APPL',
                CFBundleVersion=build, CFBundleShortVersionString=build,
                SUFeedURL='http://127.0.0.1:3277/' + name + '.xml',
                SUPublicEDKey=config['sparklePublicKey'], SUEnableAutomaticChecks=enabled,
                SUAutomaticallyUpdate=False, SUSendsSystemProfile=False,
                NSAppTransportSecurity={'NSAllowsLocalNetworking': True})
    if expected: info['UpdaterExpectedVersion'] = expected
    (app / 'Contents/Info.plist').write_bytes(plistlib.dumps(info))
    # No update is installed: the fixtures exercise real Sparkle selection/probing only.
    (root / 'feed' / (name + '.xml')).write_text('''<?xml version="1.0"?><rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"><channel><title>Local updater test</title><item><title>2.0</title><sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion><enclosure url="https://pulsecanvas.si/downloads/PulseCanvas-Studio-1.1.1-18.dmg" length="37221463" type="application/octet-stream" sparkle:version="2" sparkle:shortVersionString="2.0" /></item></channel></rss>''')
PY
python3 -m http.server 3277 --bind 127.0.0.1 --directory "$test_root/feed" > "$test_root/server.log" 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT
xcrun swiftc -O -suppress-warnings -swift-version 5 -D DIRECT_BUILD -parse-as-library \
  -F .build/sparkle -framework Sparkle -Xlinker -rpath -Xlinker "$PWD/.build/sparkle" \
  Sources/PulseCanvas/AppUpdater.swift Sources/PulseCanvas/StudioControls.swift scripts/UpdaterSmoke.swift \
  -o "$test_root/UpdaterSmoke"
for mode in available current disabled; do
    cp "$test_root/UpdaterSmoke" "$test_root/$mode.app/Contents/MacOS/UpdaterSmoke"
    codesign --force --sign - "$test_root/$mode.app"
    "$test_root/$mode.app/Contents/MacOS/UpdaterSmoke"
done
python3 - "$test_root/server.log" <<'PY'
from pathlib import Path
import sys
log = Path(sys.argv[1]).read_text()
assert 'GET /available.xml' in log, log
assert 'GET /current.xml' in log, log
assert 'GET /disabled.xml' not in log, log
print('PASS request policy: silent discovery/current-version checks; disabled automatic checks send no request')
PY
