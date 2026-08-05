#!/usr/bin/env bash
# Assembles Lyrix.app from the SPM executable. No Xcode project required.
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/build/Lyrix.app"

echo "==> building ($CONFIG)"
swift build -c "$CONFIG" --package-path "$ROOT"
BIN_DIR="$(swift build -c "$CONFIG" --package-path "$ROOT" --show-bin-path)"

echo "==> assembling bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Lyrix" "$APP/Contents/MacOS/Lyrix"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

echo "==> generating icon"
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
# Source art is 512x512, so only generate variants up to that — upscaling would
# just produce a blurry 1024 slot.
for size in 16 32 128 256; do
    sips -z "$size" "$size" "$ROOT/Resources/icon.png" \
        --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    sips -z $((size * 2)) $((size * 2)) "$ROOT/Resources/icon.png" \
        --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
sips -z 512 512 "$ROOT/Resources/icon.png" --out "$ICONSET/icon_512x512.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$ICONSET")"

# Ad-hoc signature. Enough for local use; a Developer ID identity would go here for
# distribution. Note that the ad-hoc identity changes between rebuilds, so macOS may
# ask for Automation permission again after rebuilding.
echo "==> signing (ad-hoc)"
codesign --force --sign - --identifier dev.kdembler.lyrix "$APP"

echo "==> built $APP"
