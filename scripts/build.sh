#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="${ARCH:-$(uname -m)}"
case "$ARCH" in arm64|x86_64) ;; *) echo "Unsupported architecture: $ARCH" >&2; exit 1;; esac
APP="$ROOT/build/猫咪老师.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$ROOT/.build/module-cache"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
rsync -a --delete --exclude Info.plist --exclude .DS_Store "$ROOT/Resources/" "$APP/Contents/Resources/"
xcrun swiftc -O -target "$ARCH-apple-macosx13.0" \
  -module-cache-path "$ROOT/.build/module-cache" \
  -framework AppKit -framework ImageIO \
  "$ROOT"/Sources/NyankoCompanion/*.swift \
  -o "$APP/Contents/MacOS/NyankoCompanion"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "Built ($ARCH): $APP"
