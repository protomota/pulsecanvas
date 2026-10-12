#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
for mode in portable store; do
    if [[ "$mode" == store ]]; then set -- -D STORE_BUILD; else set --; fi
    xcrun swiftc -swift-version 6 -parse-as-library "$@" \
        Sources/PulseCanvas/CreatorEngagement.swift scripts/CreatorEngagementSmoke.swift \
        -o ".build/validation/verify-creator-engagement-$mode"
    ".build/validation/verify-creator-engagement-$mode"
done
