#!/usr/bin/env python3
"""Download the official pinned Sparkle distribution; never export signing keys."""
import hashlib, json, tarfile, urllib.request
from pathlib import Path
root = Path(__file__).resolve().parents[1]
config = json.loads((root / 'macOS/DirectRelease.json').read_text())
folder = root / '.build/sparkle'
folder.mkdir(parents=True, exist_ok=True)
version = config['sparkleVersion']
archive = folder / f'Sparkle-{version}.tar.xz'
if not archive.exists():
    urllib.request.urlretrieve(f'https://github.com/sparkle-project/Sparkle/releases/download/{version}/{archive.name}', archive)
assert hashlib.sha256(archive.read_bytes()).hexdigest() == config['sparkleArchiveSHA256'], 'Sparkle SHA-256 mismatch'
with tarfile.open(archive) as package:
    for entry in package.getmembers():
        assert not Path(entry.name).is_absolute() and '..' not in Path(entry.name).parts
        if entry.issym() or entry.islnk():
            assert not Path(entry.linkname).is_absolute() and '..' not in Path(entry.linkname).parts
    package.extractall(folder)
print(f'Verified official Sparkle {version}')
