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

# Signing. A real identity gives the app a stable code signature, so macOS keeps
# its Automation permission across rebuilds; the ad-hoc fallback changes on every
# build. Override with LYRIX_SIGN_IDENTITY (use "-" to force ad-hoc).
if [[ -z "${LYRIX_SIGN_IDENTITY:-}" ]]; then
    for kind in "Developer ID Application" "Apple Development"; do
        LYRIX_SIGN_IDENTITY="$(security find-identity -v -p codesigning \
            | grep -o "\"$kind: [^\"]*\"" | head -n1 | tr -d '"')" || true
        [[ -n "$LYRIX_SIGN_IDENTITY" ]] && break
    done
fi
IDENTITY="${LYRIX_SIGN_IDENTITY:--}"

if [[ "$IDENTITY" == "-" ]]; then
    echo "==> signing (ad-hoc)"
    codesign --force --sign - --identifier dev.kdembler.lyrix "$APP"
else
    echo "==> signing ($IDENTITY)"
    # Notarization requires the hardened runtime and a secure timestamp.
    TIMESTAMP="--timestamp=none"
    [[ "$IDENTITY" == "Developer ID Application"* ]] && TIMESTAMP="--timestamp"
    codesign --force --options runtime "$TIMESTAMP" \
        --entitlements "$ROOT/Resources/Lyrix.entitlements" \
        --sign "$IDENTITY" "$APP"
fi
codesign --verify --strict "$APP"

# Notarization, for Developer ID builds when a notarytool keychain profile is given
# (create one with `xcrun notarytool store-credentials`).
if [[ -n "${LYRIX_NOTARY_PROFILE:-}" ]]; then
    if [[ "$IDENTITY" != "Developer ID Application"* ]]; then
        echo "error: notarization needs a Developer ID Application identity" >&2
        exit 1
    fi
    echo "==> notarizing"
    ZIP="$ROOT/build/Lyrix.zip"
    ditto -c -k --keepParent "$APP" "$ZIP"
    xcrun notarytool submit "$ZIP" --keychain-profile "$LYRIX_NOTARY_PROFILE" --wait
    xcrun stapler staple "$APP"
    # Re-zip so the distributable carries the stapled ticket.
    rm "$ZIP"
    ditto -c -k --keepParent "$APP" "$ZIP"
    spctl --assess --type execute --verbose "$APP"
    echo "==> notarized $ZIP"
fi

echo "==> built $APP"
