#!/bin/bash
# Builds build/OnAir.app for Apple silicon (Intel Macs aren't supported).
#   scripts/build.sh install   also copies it to /Applications and relaunches it.
#   scripts/build.sh release   also zips it as build/OnAir-<version>.zip for sharing.
set -euo pipefail
cd "$(dirname "$0")/.."

APP=build/OnAir.app
ARCHS=(--arch arm64)
swift build -c release "${ARCHS[@]}"
BIN=$(swift build -c release "${ARCHS[@]}" --show-bin-path)
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN/OnAir" "$APP/Contents/MacOS/OnAir"
# Sparkle (updates) lives in Contents/Frameworks, where the executable needs to be told to look.
ditto "$BIN/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/OnAir"
cp .build/artifacts/sparkle/Sparkle/LICENSE "$APP/Contents/Resources/Sparkle-LICENSE.txt"  # its MIT license travels with copies
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Compile the Icon Composer icon into Assets.car (+ AppIcon.icns for older consumers).
xcrun actool Resources/AppIcon.icon --compile "$APP/Contents/Resources" --platform macosx \
    --minimum-deployment-target 26.0 --app-icon AppIcon \
    --output-partial-info-plist build/AppIcon-partial.plist > /dev/null

# Accessibility permission is tied to the signature, so builds are signed with a stable identity to keep it:
# 1. "OnAir Release Signing", the self-signed certificate releases use (backup: 1Password). It holds no
#    personal details, unlike an Apple Development certificate, whose name includes its owner's email. It isn't
#    trusted by macOS, so it's selected by its SHA-1 hash, which codesign accepts.
# 2. Otherwise an Apple Development certificate, for contributors' own builds.
# 3. Otherwise ad-hoc ("-"): Accessibility has to be allowed again after every build.
IDENTITY=$(security find-certificate -c "OnAir Release Signing" -Z 2>/dev/null | awk '/SHA-1/ { print $3; exit }' || true)
[[ -n "$IDENTITY" ]] || IDENTITY=$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/ { print $2; exit }')
# The hardened runtime blocks code injection into an app that holds Accessibility access (and notarization
# requires it); OnAir's one exception is in Resources/OnAir.entitlements. Sparkle's helpers are signed
# inside-out first, as Sparkle's docs describe (Downloader keeps its own entitlements).
SPARKLE="$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
sign() { codesign --force --options runtime --sign "${IDENTITY:--}" "$@"; }
sign "$SPARKLE/XPCServices/Installer.xpc"
sign --preserve-metadata=entitlements "$SPARKLE/XPCServices/Downloader.xpc"
sign "$SPARKLE/Autoupdate"
sign "$SPARKLE/Updater.app"
sign "$APP/Contents/Frameworks/Sparkle.framework"
sign --entitlements Resources/OnAir.entitlements "$APP"
echo "Built $APP (signed by: $(codesign -dv --verbose=2 "$APP" 2>&1 | awk -F= '/^Authority/ { print $2; exit }'))"

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
