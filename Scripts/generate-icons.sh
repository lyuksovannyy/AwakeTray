#!/bin/sh
# Regenerates Resources/AppIcon.icns and the previews in docs/ from the drawing code.
set -e
root="$(cd "$(dirname "$0")/.." && pwd)"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT
swiftc -O "$root/Scripts/IconGen/main.swift" "$root/Sources/AwakeTray/TrayIcon.swift" -o "$build/icongen"
"$build/icongen" "$root"
