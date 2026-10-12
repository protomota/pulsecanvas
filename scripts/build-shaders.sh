#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$project_root/scripts/build_visual_shaders.py" "$project_root/Sources/PulseCanvas/Resources/VisualShaders" "$project_root/.build/visual-shaders/VisualShaders.metallib"
cp "$project_root/.build/visual-shaders/VisualShaders.metallib" "$project_root/Sources/PulseCanvas/Resources/VisualShaders.metallib"
