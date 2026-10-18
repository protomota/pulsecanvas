#!/usr/bin/env python3
"""Verify a locally generated, native-only visionOS app payload."""
import argparse
import hashlib
import json
import plistlib
import subprocess
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('app', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
app = args.app
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'com.protomota.pulsecanvas'
assert info['UIDeviceFamily'] == [7]
assert not (app / 'Resources').exists(), 'Flat visionOS bundle must not use the legacy Resources layout'
payload = app / 'NativeAssets'
source = root / 'Sources/PulseCanvas/Resources'
expected = {x.name for x in source.glob('*.metal')} | {'Audio/PulseCanvas.mp3', 'NativeVisualizers.json'}
actual = {x.relative_to(payload).as_posix() for x in payload.rglob('*') if x.is_file()}
assert actual == expected
for relative in expected - {'NativeVisualizers.json'}:
    assert (payload / relative).read_bytes() == (source / relative).read_bytes(), relative
catalog = json.loads((payload / 'NativeVisualizers.json').read_text())
assert catalog['activeCount'] == 336
assert (app / 'Legal/PulseCanvas-LICENSE.txt').read_bytes() == (root / 'LICENSE').read_bytes()
assert (app / 'PrivacyInfo.xcprivacy').read_bytes() == (root / 'macOS/PrivacyInfo.xcprivacy').read_bytes()
assert not any(x.suffix.lower() in {'.milk', '.dylib'} or 'projectm' in x.name.lower()
               or 'sparkle' in x.name.lower() for x in app.rglob('*'))
links = subprocess.check_output(['otool', '-L', str(app / info['CFBundleExecutable'])], text=True)
assert not any(x in links.lower() for x in ['projectm', 'sparkle', 'opengl'])
print(json.dumps(dict(nativeEffects=336, shaderFiles=len(expected)-2,
    exactNativeBytes=True, noExternalEngineOrAssets=True, legalAndPrivacy=True,
    executableSHA256=hashlib.sha256((app / info['CFBundleExecutable']).read_bytes()).hexdigest()), indent=2))
