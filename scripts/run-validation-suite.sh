#!/bin/bash
# Run every project test script and record pass/fail with timing.
#   scripts/run-validation-suite.sh [test-name ...]
cd "$(dirname "$0")/.."
validation_dir=${PULSECANVAS_VALIDATION_DIR:-.build/validation/suite}
mkdir -p "$validation_dir"
tests=("$@")
if [ ${#tests[@]} -eq 0 ]; then
  for script in scripts/test-*.sh scripts/test-*.py; do tests+=("$(basename "$script")"); done
fi
summary="$validation_dir/summary.txt"
: > "$summary"
for name in "${tests[@]}"; do
  log="$validation_dir/${name%.*}.log"
  start=$(date +%s)
  if [[ "$name" == *.py ]]; then python3 "scripts/$name" > "$log" 2>&1; else "scripts/$name" > "$log" 2>&1; fi
  status=$?
  elapsed=$(( $(date +%s) - start ))
  if [ $status -eq 0 ]; then result=PASS; else result="FAIL($status)"; fi
  printf '%-34s %-9s %4ss  %s\n' "$name" "$result" "$elapsed" "$(grep -E 'PASS|FAIL|Error|error:' "$log" | tail -1 | cut -c1-110)" | tee -a "$summary"
done
