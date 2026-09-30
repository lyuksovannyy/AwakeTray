#!/bin/sh
# Builds build/AwakeTray.app from the Swift package.
# Extra arguments go to `swift build` (e.g. --arch arm64 --arch x86_64 for a universal binary).
# Set VERSION to stamp the bundle version (e.g. VERSION=1.2.0).
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/build/AwakeTray.app"

swift build -c release --package-path "$root" "$@"
bin="$(swift build -c release --package-path "$root" "$@" --show-bin-path)"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/AwakeTray" "$app/Contents/MacOS/AwakeTray"
cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"
cp "$root/Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
if [ -n "$VERSION" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$app/Contents/Info.plist"
fi
codesign --force --sign - "$app"

echo "Built $app"
