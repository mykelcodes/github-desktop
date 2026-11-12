#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPIKE_ROOT="$PROJECT_ROOT/.build/m0"
ARCHIVE="$SPIKE_ROOT/git-lfs-darwin-arm64-v3.8.1.zip"
LICENSE="$SPIKE_ROOT/Git-LFS-LICENSE.md"
if [[ "$(uname -m)" != arm64 ]]; then
    echo "This pinned Git LFS asset is for Apple Silicon." >&2
    exit 1
fi
if [[ "$(shasum -a 256 "$ARCHIVE" | cut -d ' ' -f 1)" != 0ba10e897e0496412cd86eacaed4ed554c97ddc29bc5c709d28faa5eaaa2222c ]]; then
    echo "Git LFS archive differs from the reviewed release digest." >&2
    exit 1
fi
if [[ "$(shasum -a 256 "$LICENSE" | cut -d ' ' -f 1)" != 4fae9062ab5cdd5fb15486b728534d8aded8b4ae9d84b6d66a956f5162c366b6 ]]; then
    echo "Git LFS license differs from the reviewed pin." >&2
    exit 1
fi
unzip -p "$ARCHIVE" git-lfs-3.8.1/git-lfs > "$SPIKE_ROOT/git-runtime/bin/git-lfs"
chmod 755 "$SPIKE_ROOT/git-runtime/bin/git-lfs"
ln -sf ../../bin/git-lfs "$SPIKE_ROOT/git-runtime/libexec/git-core/git-lfs"
cp "$LICENSE" "$SPIKE_ROOT/git-runtime/notices/Git-LFS-LICENSE.md"
"$SPIKE_ROOT/git-runtime/bin/git-lfs" version
