#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Recreate the store payload; projectM code, presets, textures and updater never enter it.
rm -rf .build/store-resources/Resources .build/store-resources/Legal
mkdir -p .build/store-resources/Legal
python3 - <<'PY'
from pathlib import Path
import shutil
source = Path('Sources/PulseCanvas/Resources')
target = Path('.build/store-resources/Resources')
target.mkdir(parents=True)
for item in source.iterdir():
    if item.name == 'ProjectM':
        continue
    if item.is_dir():
        shutil.copytree(item, target / item.name)
    else:
        shutil.copy2(item, target / item.name)
PY
xcrun swift scripts/build-icon.swift .build/store-resources/AppIcon.iconset
xcrun iconutil -c icns .build/store-resources/AppIcon.iconset -o .build/store-resources/AppIcon.icns
cp LICENSE .build/store-resources/Legal/PulseCanvas-LICENSE.txt
cp docs/app-store/RevenueCat-LICENSE.txt .build/store-resources/Legal/RevenueCat-LICENSE.txt
python3 scripts/native-visualizer-catalog.py --output .build/store-resources/Resources/NativeVisualizers.json
python3 - <<'PY'
import json
from pathlib import Path
count = json.loads(Path('.build/store-resources/Resources/NativeVisualizers.json').read_text())['activeCount']
Path('.build/store-resources/Legal/Edition.txt').write_text(f'PulseCanvas Studio — Metal edition\n{count} native Metal visualizers. No projectM engine, OpenGL presets, community texture pack or Sparkle updater is included in this App Store build.\n')
PY
