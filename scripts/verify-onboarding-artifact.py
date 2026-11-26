#!/usr/bin/env python3
"""Verify bundled onboarding art and absence of capture/fixture hooks in Release."""
import hashlib
import json
from pathlib import Path
import plistlib
import sys

app = Path(sys.argv[1]).resolve()
mac = (app / "Contents/Info.plist").is_file()
info = plistlib.loads((app / ("Contents/Info.plist" if mac else "Info.plist")).read_bytes())
resources = app / "Contents/Resources/Resources" if mac else app
art = resources / "Onboarding"
source = Path(__file__).resolve().parents[1] / "Sources/PulseCanvas/Resources/Onboarding"
expected = {p.name for p in source.glob("*.png")}
assert expected == {"welcome.png", "visuals.png", "studio.png", "share.png", "support.png", "logo.png"}
assert {p.name for p in art.iterdir()} == expected
for name in expected:
    data = (art / name).read_bytes()
    assert hashlib.sha256(data).digest() == hashlib.sha256((source / name).read_bytes()).digest(), name
    assert data.startswith(b"\x89PNG\r\n\x1a\n"), name
    if name != "logo.png":
        assert data[25] == 6, f"{name} must retain RGBA transparency"
binary = app / ("Contents/MacOS" if mac else "") / info["CFBundleExecutable"]
data = binary.read_bytes()
for marker in [b"PCOnboardingQA", b"PCOnboardingStep", b"PCMobileFullSoundtrackQA", b"PCMobileQA", b"PCUITesting"]:
    assert marker not in data, f"Release contains test hook: {marker!r}"
print(json.dumps({"version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"],
                  "exactOnboardingResources": True, "transparentIllustrations": True, "testHooksAbsent": True}, indent=2))
