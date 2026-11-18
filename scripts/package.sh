#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/build.sh"
ARCH="${ARCH:-$(uname -m)}"
mkdir -p "$ROOT/dist"
ditto -c -k --sequesterRsrc --keepParent "$ROOT/build/猫咪老师.app" "$ROOT/dist/nyanko-sensei-macos-$ARCH.zip"
echo "Packaged: $ROOT/dist/nyanko-sensei-macos-$ARCH.zip"
