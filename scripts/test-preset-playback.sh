#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build/validation
./scripts/build-projectm.sh > .build/validation/projectm-build.log 2>&1
xcrun swiftc -suppress-warnings -O -parse-as-library Sources/PulseCanvas/ProjectMEngine.swift scripts/ProjectMPlaybackAudit.swift -o .build/validation/audit-projectm
.build/validation/audit-projectm "${1:-.build/validation/preset-playback.json}"
python3 - "${1:-.build/validation/preset-playback.json}" <<'PY'
import json,sys
results=json.load(open(sys.argv[1]))
failed=[x for x in results if x.get('error') or x['coverage']<.01 or x['motion']<.00005 or x['whiteCoverage']>.98 or x['medianMS']>33]
print(f"Playback quality: {len(results)-len(failed)}/{len(results)} passed")
for item in failed[:20]: print(item['title'],item.get('error','visible-output quality failure'))
sys.exit(bool(failed))
PY
