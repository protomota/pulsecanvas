#!/usr/bin/env python3
"""Verify an unsigned development Metal app against the current native sources."""
import hashlib
import json
import plistlib
import subprocess
import sys
from pathlib import Path

app = Path(sys.argv[1]).resolve()
resources = app / 'Contents/Resources/Resources'
catalog = json.loads((resources / 'NativeVisualizers.json').read_text())
expected = json.loads(subprocess.check_output([sys.executable, 'scripts/native-visualizer-catalog.py'], text=True))
assert catalog == expected, 'Bundled catalog does not match the current source'
for name, digest in catalog['shaders'].items():
    assert hashlib.sha256((resources / name).read_bytes()).hexdigest() == digest, name
    assert hashlib.sha256((Path('Sources/PulseCanvas/Resources') / name).read_bytes()).hexdigest() == digest, name
bundled = list(app.rglob('PulseCanvas.mp3'))
assert len(bundled) == 1
source = Path('Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3')
digest = hashlib.sha256(source.read_bytes()).hexdigest()
assert hashlib.sha256(bundled[0].read_bytes()).hexdigest() == digest, 'Bundled soundtrack changed'
assert not any(app.rglob('*.milk')) and not any(app.rglob('*projectM*.dylib'))
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
executable = app / 'Contents/MacOS' / info['CFBundleExecutable']
assert executable.is_file()
for binary in [executable, *list((app / 'Contents/MacOS').glob('*.dylib'))]:
    libraries = subprocess.check_output(['otool', '-L', str(binary)], text=True)
    assert 'OpenGL' not in libraries and 'projectM' not in libraries, binary
receipt = {'activeDesigns': catalog['activeCount'], 'reservedIDs': catalog['nativeCount'],
    'shaderFiles': len(catalog['shaders']), 'app': str(app), 'resourcesMatchSource': True,
    'soundtrackSHA256': digest, 'engineAndPresetAssetsAbsent': True,
    'signing': 'Not assessed; this check does not validate release signing or notarization'}
print(json.dumps(receipt, indent=2))
