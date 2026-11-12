#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPIKE_ROOT="$PROJECT_ROOT/.build/m0"
APP_PATH="$SPIKE_ROOT/Git Runtime Spike.app"
RUNTIME_PATH="$APP_PATH/Contents/Resources/GitRuntime"

if [[ ! -x "$SPIKE_ROOT/git-runtime/bin/git" ]]; then
    echo "Run bash scripts/m0/build-git-runtime.sh first." >&2
    exit 1
fi
GIT_WORKSPACE_BUILD_DIR="$PROJECT_ROOT/.build" bash "$PROJECT_ROOT/scripts/build-app.sh" release
ditto "$PROJECT_ROOT/.build/app/Git Workspace.app" "$APP_PATH"
ditto "$SPIKE_ROOT/git-runtime" "$RUNTIME_PATH"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier dev.gitworkspace.runtime-spike' "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Add :GitWorkspaceBundledGit bool true' "$APP_PATH/Contents/Info.plist"
while IFS= read -r -d '' executable; do
    if file "$executable" | /usr/bin/grep -q 'Mach-O'; then
        codesign --force --options runtime --sign - "$executable"
    fi
done < <(find "$RUNTIME_PATH" -type f -perm -111 -print0)
codesign --force --options runtime --sign - "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
"$RUNTIME_PATH/bin/git" --version
"$RUNTIME_PATH/bin/git" --exec-path
echo "Ad-hoc hardened-runtime experiment built at $APP_PATH"
