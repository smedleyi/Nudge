#!/bin/bash
set -e

REPO_URL="https://github.com/smedleyi/Nudge.git"

# Running from a local checkout (e.g. `bash install.sh`) vs. piped via curl.
# BASH_SOURCE[0] is a real file path in the former case and something like
# "bash" (not a file) in the latter, so the -f check naturally distinguishes them.
if [ -f "${BASH_SOURCE[0]}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/Package.swift" ]; then
    cd "$(dirname "${BASH_SOURCE[0]}")"
else
    echo "Cloning Nudge..."
    WORKDIR="$(mktemp -d)"
    trap 'rm -rf "$WORKDIR"' EXIT
    git clone --depth 1 "$REPO_URL" "$WORKDIR/Nudge"
    cd "$WORKDIR/Nudge"
fi

echo "Building Nudge (release)..."
swift build -c release

BUNDLE="/Applications/Nudge.app"

# Kill running instance if any
pkill -x Nudge 2>/dev/null || true
sleep 0.5

echo "Installing to $BUNDLE..."
rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp .build/release/Nudge "$BUNDLE/Contents/MacOS/Nudge"
chmod +x "$BUNDLE/Contents/MacOS/Nudge"
cp Info.plist "$BUNDLE/Contents/Info.plist"
cp AppIcon.icns "$BUNDLE/Contents/Resources/AppIcon.icns"

echo "Signing..."
codesign --force --deep --sign - \
  --identifier "com.isaac.nudge" \
  "$BUNDLE"

echo "Done. Opening Nudge..."
open "$BUNDLE"
