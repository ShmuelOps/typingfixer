#!/bin/bash
# Builds build/LayoutFix.app (universal, ad-hoc signed) and build/LayoutFix-<version>.dmg.
# Fails if the binary links or references any networking API.
set -euo pipefail
VERSION="${1:-0.0.0-dev}"
cd "$(dirname "$0")/.."

for arch in arm64 x86_64; do
  swift build -c release --triple "$arch-apple-macosx13.0"
done

rm -rf build
APP=build/LayoutFix.app
BIN=$APP/Contents/MacOS/LayoutFix
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
lipo -create -output "$BIN" .build/{arm64,x86_64}-apple-macosx/release/LayoutFix
sed "s/__VERSION__/$VERSION/" Resources/Info.plist > "$APP/Contents/Info.plist"

"$BIN" --selftest

# No-network guarantee: no networking frameworks, socket/DNS/URL-loading symbols, or URLs.
if otool -L "$BIN" | grep -E 'Network\.framework|CFNetwork'; then echo "::error::links a networking framework"; exit 1; fi
if nm -u "$BIN" | grep -E '_(socket|connect|getaddrinfo|gethostbyname|nw_[a-z_]+|CFSocket[A-Za-z]*|CFStream[A-Za-z]*|CFHTTP[A-Za-z]*)$|URLSession|NSURLConnection|NSURLRequest'; then
  echo "::error::references a networking symbol"; exit 1
fi
if strings -a "$BIN" | grep -E 'https?://'; then echo "::error::contains a URL"; exit 1; fi
echo "no-network check ok"

codesign --force --sign - --options runtime "$APP"

mkdir build/dmg
cp -R "$APP" build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -volname LayoutFix -srcfolder build/dmg -ov -format UDZO "build/LayoutFix-$VERSION.dmg"
rm -rf build/dmg
