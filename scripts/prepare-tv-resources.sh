#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Clear only this target's generated allowlisted resources, never source assets.
rm -rf .build/tv-resources/Resources .build/tv-resources/NativeAssets .build/tv-resources/Legal
mkdir -p .build/tv-resources/NativeAssets/Audio .build/tv-resources/Legal
python3 - <<'PY'
from pathlib import Path
import shutil
source = Path('Sources/PulseCanvas/Resources')
target = Path('.build/tv-resources/NativeAssets')
# Explicit allowlist: external presets, textures, projectM and updater never enter this target.
for item in source.glob('*.metal'):
    shutil.copy2(item, target / item.name)
shutil.copy2(source / 'Audio/PulseCanvas.mp3', target / 'Audio/PulseCanvas.mp3')
shutil.copy2(Path('LICENSE'), Path('.build/tv-resources/Legal/PulseCanvas-LICENSE.txt'))
PY
python3 scripts/native-visualizer-catalog.py --output .build/tv-resources/NativeAssets/NativeVisualizers.json
