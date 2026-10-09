#!/bin/bash
# Builds build/OnAir.app for Apple silicon (Intel Macs aren't supported).
#   scripts/build.sh install   also copies it to /Applications and relaunches it.
#   scripts/build.sh release   also zips it as build/OnAir-<version>.zip for sharing.
set -euo pipefail
cd "$(dirname "$0")/.."

APP=build/OnAir.app
ARCHS=(--arch arm64)
swift build -c release "${ARCHS[@]}"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release "${ARCHS[@]}" --show-bin-path)/OnAir" "$APP/Contents/MacOS/OnAir"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Compile the Icon Composer icon into Assets.car (+ AppIcon.icns for older consumers).
xcrun actool Resources/AppIcon.icon --compile "$APP/Contents/Resources" --platform macosx \
    --minimum-deployment-target 26.0 --app-icon AppIcon \
    --output-partial-info-plist build/AppIcon-partial.plist > /dev/null

# Accessibility permission is tied to the signature: an Apple Development identity keeps it across
# rebuilds; ad-hoc ("-") signing means re-granting it after every build.
IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/ { print $2; exit }')
# Hardened runtime is required for notarization; OnAir needs no exceptions to it.
codesign --force --options runtime --sign "${IDENTITY:--}" "$APP"
echo "Built $APP (signed: ${IDENTITY:-ad-hoc})"

if [[ "${1:-}" == "install" ]]; then
    pkill -x OnAir || true
    rm -rf /Applications/OnAir.app
    cp -R "$APP" /Applications/
    open /Applications/OnAir.app
    echo "Installed /Applications/OnAir.app"
fi

if [[ "${1:-}" == "release" ]]; then
    VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
    ZIP=build/OnAir-$VERSION.zip
    ditto -c -k --keepParent "$APP" "$ZIP"  # ditto keeps the signature intact; plain zip can break it
    echo "Packaged $ZIP"
fi
