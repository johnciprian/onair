#!/bin/bash
# Builds build/OnAir.app. `scripts/build.sh install` also copies it to /Applications and relaunches it.
set -euo pipefail
cd "$(dirname "$0")/.."

APP=build/OnAir.app
swift build -c release
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/OnAir" "$APP/Contents/MacOS/OnAir"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Accessibility permission is tied to the signature: an Apple Development identity keeps it across
# rebuilds; ad-hoc ("-") signing means re-granting it after every build.
IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/ { print $2; exit }')
codesign --force --sign "${IDENTITY:--}" "$APP"
echo "Built $APP (signed: ${IDENTITY:-ad-hoc})"

if [[ "${1:-}" == "install" ]]; then
    pkill -x OnAir || true
    rm -rf /Applications/OnAir.app
    cp -R "$APP" /Applications/
    open /Applications/OnAir.app
    echo "Installed /Applications/OnAir.app"
fi
