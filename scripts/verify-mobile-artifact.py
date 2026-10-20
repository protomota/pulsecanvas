#!/usr/bin/env python3
"""Check the actual native-only iOS app bundle against this checkout."""
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import sys

app = Path(sys.argv[1]).resolve()
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert set(info['UIDeviceFamily']) == {1, 2}, 'Both iPhone and iPad must be supported'
assert info['MinimumOSVersion'] == '18.0'
assert info.get('UIBackgroundModes') == ['audio'], 'Background playback mode is missing or overbroad'
root = app / 'NativeAssets'
catalog = json.loads((root / 'NativeVisualizers.json').read_text())
expected = json.loads(subprocess.check_output([sys.executable, 'scripts/native-visualizer-catalog.py'], text=True))
assert catalog == expected, 'Native catalog does not match source'
for name, digest in catalog['shaders'].items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest, name
assert hashlib.sha256((root / 'Audio/PulseCanvas.mp3').read_bytes()).digest() == hashlib.sha256(Path('Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3').read_bytes()).digest()
assert (app / 'Legal/PulseCanvas-LICENSE.txt').read_bytes() == Path('LICENSE').read_bytes()
assert (app / 'PrivacyInfo.xcprivacy').read_bytes() == Path('macOS/PrivacyInfo.xcprivacy').read_bytes()
assert not list(app.rglob('*.milk'))
assert not any('sparkle' in p.name.lower() or 'projectm' in p.name.lower() for p in app.rglob('*'))
binary = app / info['CFBundleExecutable']
release_bytes = binary.read_bytes()
assert all(marker not in release_bytes for marker in (b'PCMobileQA', b'PCMobileRadioQA')), 'Debug fixture leaked into Release'
linked = subprocess.check_output(['otool', '-L', str(binary)], text=True)
assert 'OpenGL' not in linked and 'projectM' not in linked
print(json.dumps({'app': str(app), 'version': info['CFBundleShortVersionString'], 'build': info['CFBundleVersion'],
    'deviceFamilies': info['UIDeviceFamily'], 'activeEffects': catalog['activeCount'], 'resourcesMatchSource': True,
    'externalEffectsAbsent': True, 'debugFixtureAbsent': True, 'signing': 'not assessed'}, indent=2))
