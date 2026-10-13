#!/usr/bin/env python3
"""Read red Finder labels from a Metal review folder; never change files or the app."""
import argparse
import ctypes
import json
import plistlib
import re
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('folder', type=Path)
args = parser.parse_args()
lib = ctypes.CDLL(None, use_errno=True)
get = lib.getxattr
get.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint32, ctypes.c_int]
get.restype = ctypes.c_ssize_t

def attribute(path: Path, name: str) -> bytes | None:
    size = get(str(path).encode(), name.encode(), None, 0, 0, 0)
    if size < 0:
        return None
    buffer = ctypes.create_string_buffer(size)
    length = get(str(path).encode(), name.encode(), buffer, size, 0, 0)
    return buffer.raw[:length] if length >= 0 else None

keepers = {}
for path in sorted(args.folder.rglob('*.mp4')):
    identity = re.match(r'^(\d{3})\s*-', path.name)
    if not identity:
        continue
    raw = attribute(path, 'com.apple.metadata:_kMDItemUserTags')
    tags = plistlib.loads(raw) if raw else []
    info = attribute(path, 'com.apple.FinderInfo')
    label = (int.from_bytes(info[8:10], 'big') >> 1) & 7 if info else 0
    # Finder stores the color index after a newline; Red is index 6.
    if label == 6 or any(str(tag).endswith('\n6') for tag in tags):
        scene = int(identity.group(1))
        keepers.setdefault(scene, []).append({'path': str(path.resolve()), 'tags': tags, 'finderLabel': label})
print(json.dumps({'policy': 'Red Finder label keeps an effect', 'keeperCount': len(keepers),
                  'keepers': sorted(keepers), 'evidence': keepers}, indent=2))
