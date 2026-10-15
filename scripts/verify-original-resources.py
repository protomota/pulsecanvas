#!/usr/bin/env python3
"""Inspect an actual original-Metal app payload without requiring a signature."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('app', type=Path)
args = parser.parse_args()
app = args.app.resolve()
root = Path(__file__).resolve().parent.parent
info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
exe = app / 'Contents/MacOS' / info['CFBundleExecutable']
resources = app / 'Contents/Resources'
catalogs = list(resources.rglob('NativeVisualizers.json'))
assert len(catalogs) == 1, 'Expected one native resource catalog'
catalog_path = catalogs[0]
shader_root = catalog_path.parent
catalog = json.loads(catalog_path.read_text())
expected = json.loads(subprocess.check_output(['python3', str(root / 'scripts/native-visualizer-catalog.py')]))
assert catalog == expected, 'App catalog differs from current source'
assert catalog['schema'] == 2
assert not set(catalog['retiredScenes']).intersection(effect['scene'] for effect in catalog['effects'])
for path in app.rglob('*'):
    assert path.suffix.lower() not in ('.milk', '.ll'), f'Withdrawn source/preset bundled: {path}'
    assert path.name != 'VisualShaders.metallib', 'Recovered shader binary bundled'
    assert 'projectm' not in path.name.lower(), f'External engine resource bundled: {path}'
for name, digest in catalog['shaders'].items():
    assert hashlib.sha256((shader_root / name).read_bytes()).hexdigest() == digest, name
assert (resources / 'Legal/PulseCanvas-LICENSE.txt').read_bytes() == (root / 'LICENSE').read_bytes()
imports = subprocess.check_output(['otool', '-L', str(exe)], text=True)
assert not any(value in imports for value in ['OpenGL.framework', 'libprojectM']), imports
symbols = subprocess.check_output(['nm', '-u', str(exe)], text=True)
assert '_projectm_' not in symbols and '_CGLCreateContext' not in symbols
print(json.dumps({'app': str(app), 'activeNativeEffects': catalog['nativeCount'],
    'retiredNativeIDs': catalog['retiredScenes'], 'externalPresets': 0,
    'recoveredShaders': 0, 'openGLImports': False, 'shaderHashesMatch': True,
    'signatureChecked': False}, indent=2))
