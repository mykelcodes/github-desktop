#!/bin/bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SPIKE_ROOT="$PROJECT_ROOT/.build/m0"
ARCHIVE="$SPIKE_ROOT/git-2.56.1.tar.xz"
RUNTIME="$SPIKE_ROOT/git-runtime"
EXPECTED_SHA="f0b0bf89264b9bd2e1c640363e7529643989da76281600473c50745cd34a607f"

if [[ ! -f "$ARCHIVE" ]]; then
    echo "Download https://www.kernel.org/pub/software/scm/git/git-2.56.1.tar.xz to $ARCHIVE" >&2
    exit 1
fi
ACTUAL_SHA="$(shasum -a 256 "$ARCHIVE" | cut -d ' ' -f 1)"
if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
    echo "Git source hash differs from the reviewed pin." >&2
    exit 1
fi

tar -xJf "$ARCHIVE" -C "$SPIKE_ROOT"
export MACOSX_DEPLOYMENT_TARGET=15.0
make -C "$SPIKE_ROOT/git-2.56.1" -j4 \
    prefix="$RUNTIME" RUNTIME_PREFIX=YesPlease \
    NO_GETTEXT=YesPlease NO_TCLTK=YesPlease NO_PERL=YesPlease NO_PYTHON=YesPlease \
    CC=/usr/bin/clang CFLAGS="-O2 -mmacosx-version-min=15.0" install \
    > "$SPIKE_ROOT/git-build.log" 2>&1
mkdir -p "$RUNTIME/notices"
cp "$SPIKE_ROOT/git-2.56.1/COPYING" "$RUNTIME/notices/Git-COPYING"
"$RUNTIME/bin/git" --version
otool -L "$RUNTIME/bin/git" "$RUNTIME/libexec/git-core/git-remote-http"
echo "Experimental runtime built at $RUNTIME. Clean-Mac and distribution validation remain open."
