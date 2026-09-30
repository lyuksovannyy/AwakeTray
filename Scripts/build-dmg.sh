#!/bin/sh
# Packs build/AwakeTray.app into a disk image with a shortcut to Applications,
# so installing is "open the image, drag the app across".
# Usage: Scripts/build-dmg.sh [output.dmg]   (run Scripts/build-app.sh first)
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
app="$root/build/AwakeTray.app"
dmg="${1:-$root/build/AwakeTray.dmg}"

[ -d "$app" ] || { echo "Missing $app: run Scripts/build-app.sh first" >&2; exit 1; }

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
# ditto keeps the bundle's code signature and metadata intact.
ditto "$app" "$staging/AwakeTray.app"
ln -s /Applications "$staging/Applications"

rm -f "$dmg"
hdiutil create -volname AwakeTray -srcfolder "$staging" -fs HFS+ -format UDZO -quiet "$dmg"

echo "Built $dmg"
