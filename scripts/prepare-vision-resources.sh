#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Clear only this target's generated allowlisted resources, never source assets.
rm -rf .build/vision-resources/Resources .build/vision-resources/NativeAssets .build/vision-resources/Legal
mkdir -p .build/vision-resources/NativeAssets/Audio .build/vision-resources/Legal
python3 - <<'PY'
from pathlib import Path
import shutil
source = Path('Sources/PulseCanvas/Resources')
target = Path('.build/vision-resources/NativeAssets')
# Explicit allowlist: external presets, textures, projectM and updater never enter this target.
for item in source.glob('*.metal'):
    shutil.copy2(item, target / item.name)
shutil.copy2(source / 'Audio/PulseCanvas.mp3', target / 'Audio/PulseCanvas.mp3')
shutil.copy2(Path('LICENSE'), Path('.build/vision-resources/Legal/PulseCanvas-LICENSE.txt'))
PY
python3 scripts/native-visualizer-catalog.py --output .build/vision-resources/NativeAssets/NativeVisualizers.json
