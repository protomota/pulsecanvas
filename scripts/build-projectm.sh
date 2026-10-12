#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
SOURCE=.build/projectm/source
if [ ! -f "$SOURCE/CMakeLists.txt" ]; then
    mkdir -p "$SOURCE"
    tar -xzf third_party/projectm-source.tar.gz -C "$SOURCE"
fi
cmake -S "$SOURCE" -B .build/projectm/build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PWD/.build/projectm/install" -DENABLE_SYSTEM_PROJECTM_EVAL=OFF -DENABLE_PLAYLIST=OFF -DBUILD_TESTING=OFF -DENABLE_SDL_UI=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0
cmake --build .build/projectm/build --parallel 8
cmake --install .build/projectm/build
