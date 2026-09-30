#!/bin/sh
# Builds build/AwakeTray.app from the Swift package.
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/build/AwakeTray.app"

swift build -c release --package-path "$root"
bin="$(swift build -c release --package-path "$root" --show-bin-path)"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin/AwakeTray" "$app/Contents/MacOS/AwakeTray"
cp "$root/Resources/Info.plist" "$app/Contents/Info.plist"
cp "$root/Resources/AppIcon.icns" "$app/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$app"

echo "Built $app"
