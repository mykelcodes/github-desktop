#!/bin/bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="${GIT_WORKSPACE_BUILD_DIR:-$PROJECT_ROOT/.build}"
mkdir -p "$BUILD_ROOT"
BUILD_ROOT="$(cd "$BUILD_ROOT" && pwd)"

export CLANG_MODULE_CACHE_PATH="$BUILD_ROOT/clang-module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_ROOT/swift-module-cache"

SWIFT_OPTIONS=(
    --package-path "$PROJECT_ROOT"
    --scratch-path "$BUILD_ROOT"
    --cache-path "$BUILD_ROOT/swiftpm-cache"
    --config-path "$BUILD_ROOT/swiftpm-config"
    --security-path "$BUILD_ROOT/swiftpm-security"
    # The manifest has no external dependencies; allow builds inside another sandbox.
    --disable-sandbox
)
