#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/swift-env.sh"

CONFIGURATION="${1:-debug}"
if [[ "$#" -gt 1 || ( "$CONFIGURATION" != debug && "$CONFIGURATION" != release ) ]]; then
    echo "Usage: $0 [debug|release]" >&2
    exit 2
fi

swift build "${SWIFT_OPTIONS[@]}" --configuration "$CONFIGURATION" --product GitWorkspace
BIN_PATH="$(swift build "${SWIFT_OPTIONS[@]}" --configuration "$CONFIGURATION" --show-bin-path)"
APP_PATH="$BUILD_ROOT/app/Git Workspace.app"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$BIN_PATH/GitWorkspace" "$APP_PATH/Contents/MacOS/GitWorkspace"
cp "$PROJECT_ROOT/Resources/Info.plist" "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -lint "$APP_PATH/Contents/Info.plist"
/usr/bin/codesign --force --sign - "$APP_PATH"
/usr/bin/codesign --verify --strict --verbose=2 "$APP_PATH"

echo "Built: $APP_PATH"
echo "Local development build: ad-hoc signed, not notarized, using installed Git (no bundled Git)."
