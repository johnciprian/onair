#!/bin/bash
# Publishes the version in Resources/Info.plist as a GitHub release, with the appcast that tells installed copies
# (through Sparkle) that it exists. Before running, raise both versions in Resources/Info.plist:
# CFBundleShortVersionString (what people see, e.g. 1.1) and CFBundleVersion (a whole number that only goes up),
# and add a "## <version>" section to CHANGELOG.md.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(plutil -extract CFBundleShortVersionString raw Resources/Info.plist)
TAG="v$VERSION"
if gh release view "$TAG" > /dev/null 2>&1; then
    echo "$TAG is already released. Raise the versions in Resources/Info.plist first."; exit 1
fi
# This version's section of CHANGELOG.md (the lines under "## <version>", up to the next "## ").
NOTES=$(awk -v heading="## $VERSION" '/^## / { inside = ($0 == heading); next } inside' CHANGELOG.md)
if [[ -z "${NOTES//[[:space:]]/}" ]]; then
    echo "Add a \"## $VERSION\" section to CHANGELOG.md first."; exit 1
fi
if [[ -n $(git status --porcelain) || $(git rev-parse HEAD) != $(git rev-parse @{u}) ]]; then
    echo "Commit and push everything first, so the release matches what's on GitHub."; exit 1
fi

scripts/build.sh release
OUT=build/release
rm -rf "$OUT" && mkdir -p "$OUT"
cp "build/OnAir-$VERSION.zip" "$OUT/"
# A notes file named like the zip goes into the appcast, so the update window lists what's new.
printf '%s\n' "$NOTES" > "$OUT/OnAir-$VERSION.md"
# Signs the zip with the update key in the login Keychain (backup: 1Password, "OnAir Sparkle update signing key")
# and writes appcast.xml. Installed copies read it from the latest release (SUFeedURL in Info.plist).
.build/artifacts/sparkle/Sparkle/bin/generate_appcast --account onair --embed-release-notes \
    --download-url-prefix "https://github.com/johnciprian/onair/releases/download/$TAG/" "$OUT"
gh release create "$TAG" "$OUT/OnAir-$VERSION.zip" "$OUT/appcast.xml" --title "OnAir $VERSION" --notes "$NOTES"
