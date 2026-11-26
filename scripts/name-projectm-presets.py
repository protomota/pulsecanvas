#!/usr/bin/env python3
"""Assign stable two-word display names and shared icons; retain upstream credits."""
import json
import sys
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'Sources/PulseCanvas/Resources/ProjectM'
vocabulary = json.loads((root / 'naming.json').read_text())
catalog = json.loads((root / 'catalog.json').read_text())
if '--icons-only' in sys.argv:
    for preset in catalog:
        value = 14695981039346656037
        for byte in preset['id'].encode():
            value = ((value ^ byte) * 1099511628211) & ((1 << 64) - 1)
        preset['icon'] = vocabulary['icons'][value % len(vocabulary['icons'])]
    (root / 'catalog.json').write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')
    print(f'Updated {len(catalog):,} icons from {len(vocabulary["icons"])} designs; names and identities preserved')
    sys.exit(0)

sources = root.parents[1]
native = (sources / 'VisualizerRenderer.swift').read_text().split('static let nativeSceneNames = ')[1].split('\n')[0]
used = set(re.findall(r'"([^"]+)"', native))
used.update(re.findall(r'case \.\w+: return "([^"]+)"', (sources / 'OriginalGeometry.swift').read_text()))
reserved = len(used)

def stable_hash(text):
    value = 14695981039346656037
    for byte in text.encode():
        value = ((value ^ byte) * 1099511628211) & ((1 << 64) - 1)
    return value

for preset in catalog:
    value = stable_hash(preset['id'])
    slot = value % (len(vocabulary['adjectives']) * len(vocabulary['nouns']))
    while True:
        name = vocabulary['adjectives'][slot // len(vocabulary['nouns'])] + ' ' + vocabulary['nouns'][slot % len(vocabulary['nouns'])]
        if name not in used:
            break
        slot = (slot + 1) % (len(vocabulary['adjectives']) * len(vocabulary['nouns']))
    preset['originalTitle'] = preset.get('originalTitle', preset['title'])
    preset['title'] = name
    preset['icon'] = vocabulary['icons'][value % len(vocabulary['icons'])]
    used.add(name)

assert len(used) == len(catalog) + reserved
assert all(len(preset['title'].split()) == 2 for preset in catalog)
(root / 'catalog.json').write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')
print(f'Named {len(catalog):,} presets with {len(vocabulary["icons"])} shared icons')
