#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/swift-env.sh"

exec swift test "${SWIFT_OPTIONS[@]}" "$@"
