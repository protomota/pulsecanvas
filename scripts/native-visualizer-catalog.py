#!/usr/bin/env python3
"""Generate the native resource catalog from the ordered NativeEffects registry."""
import argparse
import hashlib
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
sources = root / 'Sources/PulseCanvas'
registry = (sources / 'NativeEffects.swift').read_text()
original = (sources / 'OriginalGeometry.swift').read_text().split('static var sceneNames:', 1)[0]
titles = dict(re.findall(r'case \.(\w+): return "([^"]+)"', original))
body = registry.split('static let all: [NativeEffect] = [', 1)[1].split('\n    ]\n', 1)[0]
effects = []
for entry in re.findall(r'^\s*\.(original|metal|retired)\((.*)\),?\s*$', body, re.M):
    kind, arguments = entry
    literal = re.match(r'"([^"]+)"', arguments)
    name = literal.group(1) if literal else titles[re.match(r'OriginalGeometry\.Scene\.(\w+)\.title', arguments).group(1)]
    icon = re.search(r'icon: "([^"]+)"', arguments).group(1)
    shader = re.search(r'icon: "[^"]+", "(\w+)", in: (\w+)', arguments) if kind == 'metal' else None
    replacement = re.search(r'replacement: (\d+)', arguments) if kind == 'retired' else None
    effects.append({'name': name, 'icon': icon, 'shader': shader.group(1) if shader else None,
                    'replacement': int(replacement.group(1)) if replacement else None})
# Retired designs keep their IDs for migration; only offered designs need unique names and icons.
active = [e for e in effects if e['replacement'] is None]
names = [e['name'] for e in active]
icons = [e['icon'] for e in active]
assert len(names) == len(set(names)), 'Native names must be unique'
assert len(effects) >= 31
assert all(effects[e['replacement']]['replacement'] is None for e in effects if e['replacement'] is not None), 'Retired designs must open an offered design'
files = re.search(r'static let shaderFiles = \[(.*?)\]', registry, re.S).group(1)
shader_paths = ['Canvas.metal', 'SpatialVisuals.metal', 'Strobe.metal', 'NativeCommon.metal', 'NativeExpansionCommon.metal'] + re.findall(r'"([^"]+\.metal)"', files)
catalog = {
    'schema': 1,
    'nativeCount': len(effects),
    'activeCount': len(active),
    'effects': [{'id': f'native:{i}', 'scene': i, 'name': e['name'], 'icon': e['icon']}
                | ({'retired': True, 'replacement': f"native:{e['replacement']}"} if e['replacement'] is not None else {})
                for i, e in enumerate(effects)],
    'shaders': {p: hashlib.sha256((sources / 'Resources' / p).read_bytes()).hexdigest() for p in shader_paths},
}
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path)
args = parser.parse_args()
encoded = json.dumps(catalog, indent=2) + '\n'
if args.output:
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(encoded)
else:
    print(encoded, end='')
