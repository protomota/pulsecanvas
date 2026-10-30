#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Clear only this target's generated allowlisted resources, never source assets.
rm -rf .build/mobile-resources/Resources .build/mobile-resources/NativeAssets .build/mobile-resources/Legal
mkdir -p .build/mobile-resources/NativeAssets/Audio .build/mobile-resources/Legal
python3 - <<'PY'
from pathlib import Path
import shutil
source = Path('Sources/PulseCanvas/Resources')
target = Path('.build/mobile-resources/NativeAssets')
# Explicit allowlist: external presets, textures, projectM and updater never enter this target.
for item in source.glob('*.metal'):
    shutil.copy2(item, target / item.name)
shutil.copy2(source / 'Audio/PulseCanvas.mp3', target / 'Audio/PulseCanvas.mp3')
shutil.copy2(Path('LICENSE'), Path('.build/mobile-resources/Legal/PulseCanvas-LICENSE.txt'))
shutil.copy2(Path('docs/app-store/RevenueCat-LICENSE.txt'), Path('.build/mobile-resources/Legal/RevenueCat-LICENSE.txt'))
PY
python3 scripts/native-visualizer-catalog.py --output .build/mobile-resources/NativeAssets/NativeVisualizers.json
