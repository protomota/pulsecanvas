#!/bin/bash
set -euo pipefail
cd "$SRCROOT"
frameworks="$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH"
mkdir -p "$frameworks"
cp .build/projectm/install/lib/libprojectM-4.4.2.0.dylib "$frameworks/libprojectM.dylib"
install_name_tool -id @rpath/libprojectM.dylib "$frameworks/libprojectM.dylib"
if [[ "$CODE_SIGNING_ALLOWED" != NO && -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]]; then
    /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --options runtime "$frameworks/libprojectM.dylib"
fi
