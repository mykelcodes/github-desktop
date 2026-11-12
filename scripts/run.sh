#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/swift-env.sh"

"$PROJECT_ROOT/scripts/build-app.sh" debug
if [[ "$#" -eq 0 ]]; then
    /usr/bin/open "$BUILD_ROOT/app/Git Workspace.app"
else
    /usr/bin/open "$BUILD_ROOT/app/Git Workspace.app" --args "$@"
fi
