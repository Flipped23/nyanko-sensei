#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/build.sh"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nyanko-smoke.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
"$ROOT/build/猫咪老师.app/Contents/MacOS/NyankoCompanion" --smoke-test \
  --test-data "$TEST_DIR/preferences.json" --report "$TEST_DIR/report.json"
python3 - "$TEST_DIR/report.json" <<'PY'
import json,sys
with open(sys.argv[1]) as f:
    result=json.load(f)
assert result['ok'],result
print(json.dumps(result,ensure_ascii=False,indent=2))
PY
