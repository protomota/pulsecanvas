#!/bin/bash
# Local direct-download packaging; does not publish or submit an App Store build.
set -euo pipefail
cd "$(dirname "$0")/.."
profile="${1:-${NOTARYTOOL_PROFILE:-}}"
resume="${2:-}"
[[ -n "$profile" && ( -z "$resume" || "$resume" == --resume ) ]] || { echo 'Usage: scripts/release-direct-dmg.sh EXISTING_NOTARYTOOL_KEYCHAIN_PROFILE [--resume]' >&2; exit 1; }
identity="${DEVELOPER_ID_APPLICATION:-Developer ID Application: Protomota, LLC (22HV69L32T)}"
python="${DMG_PYTHON:-$PWD/.build/dmg-tools/bin/python}"
[[ -x "$python" ]] || { echo 'Prepare Python 3.12 build tools as documented in packaging/macos/README.md.' >&2; exit 1; }
"$python" -c 'import sys; from importlib.metadata import version; assert sys.version_info[:2] == (3,12); assert all(version(k)==v for k,v in {"dmgbuild":"1.6.7","ds-store":"1.3.3","mac-alias":"2.2.3"}.items())'
# DIRECT_APP permits finishing an already-built signed bundle without rebuilding.
if [[ -z "${DIRECT_APP:-}" && "$resume" != --resume ]]; then
  ./scripts/build-direct-release.sh
fi
app="${DIRECT_APP:-$PWD/build/direct/PulseCanvas Studio.app}"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")
build=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$app/Contents/Info.plist")
image="${DIRECT_DMG:-$PWD/build/direct-distribution/PulseCanvas-Studio-$version-$build.dmg}"
if [[ "$resume" == --resume ]]; then
  [[ -f "$image" ]] || { echo "No image to resume: $image" >&2; exit 1; }
  # Prove that the existing image is an exact copy of the signed source bundle.
  "$python" scripts/package-mac-dmg.py --app "$app" --output "$image" --verify-only
else
  [[ ! -e "$image" ]] || { echo "Output exists: $image; set DIRECT_DMG to a fresh path or use --resume." >&2; exit 1; }
  "$python" scripts/package-mac-dmg.py --app "$app" --output "$image"
fi
if [[ "$resume" == --resume ]] && codesign --verify --strict "$image" && \
   codesign --display --verbose=2 "$image" 2>&1 | /usr/bin/grep -Fx "Authority=$identity" >/dev/null; then
  echo 'Retaining the verified existing Developer ID image signature.'
else
  codesign --force --timestamp --sign "$identity" "$image"
fi
xcrun notarytool submit "$image" --keychain-profile "$profile" --wait --output-format json > "${image%.dmg}.notarization.json"
"$python" - "${image%.dmg}.notarization.json" <<'PY'
import json, sys
result = json.load(open(sys.argv[1]))
if result.get('status') != 'Accepted':
    raise SystemExit(f"Apple notarization did not accept the DMG: {result.get('status')}")
print('Apple notarization: Accepted')
PY
xcrun stapler staple "$image"
xcrun stapler validate "$image"
codesign --verify --strict --verbose=2 "$image"
spctl --assess --type open --context context:primary-signature --verbose=2 "$image"
"$python" scripts/package-mac-dmg.py --app "$app" --output "$image" --verify-only --release-checks
account=$(python3 -c 'import json; print(json.load(open("macOS/DirectRelease.json"))["sparkleKeychainAccount"])')
signature=$(.build/sparkle/bin/sign_update --account "$account" -p "$image")
.build/sparkle/bin/sign_update --account "$account" --verify "$image" "$signature"
"$python" - "$app" "$image" "$signature" <<'PY'
import hashlib, json, plistlib, subprocess, sys
from pathlib import Path
app, image, signature = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
config = json.loads(Path('macOS/DirectRelease.json').read_text())
subprocess.run(['xcrun', 'swift', 'scripts/verify-update-signature.swift', str(image), signature, config['sparklePublicKey']], check=True)
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
report = {'version': info['CFBundleShortVersionString'], 'build': info['CFBundleVersion'],
          'file': image.name, 'bytes': image.stat().st_size,
          'sha256': hashlib.sha256(image.read_bytes()).hexdigest(),
          'edSignature': signature, 'sparklePublicKeyVerified': True,
          'notarization': 'Accepted', 'stapled': True, 'published': False}
image.with_suffix('.release.json').write_text(json.dumps(report, indent=2) + '\n')
print('Verified local installer:', image)
PY
