#!/bin/sh
# typst-digests.sh — every digest tools/install-typst.sh pins is the digest of typst's release.
#
#   sh .github/typst-digests.sh
#
# Run by CI's bundle job. The toolchain action installs typst through install-typst.sh, which
# proves the digest for the runner's own architecture, x86_64. The script pins one for each
# architecture it installs, and a repository whose CI runs on another would be the first to find
# a wrong one. Each archive is downloaded and checked here, and none is run.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "typst-digests: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

version=$(sed -n 's/^TYPST_VERSION=//p' tools/install-typst.sh)
[ -n "$version" ] || fail "tools/install-typst.sh names no TYPST_VERSION"
pins=$(sed -n 's/^TYPST_SHA256_\([A-Z0-9_]*\)=\([0-9a-f]*\)$/\1 \2/p' tools/install-typst.sh)
[ "$(printf '%s\n' "$pins" | grep -c .)" -ge 2 ] || fail "tools/install-typst.sh pins fewer than two digests"
printf '%s\n' "$pins" | while read -r arch sum; do
    arch=$(printf '%s' "$arch" | tr '[:upper:]' '[:lower:]')
    name=typst-$arch-unknown-linux-musl.tar.xz
    curl --fail --silent --show-error --location \
        "https://github.com/typst/typst/releases/download/v$version/$name" --output "$tmp/$name"
    echo "$sum  $tmp/$name" | sha256sum -c - >/dev/null \
        || fail "$name of typst $version is not the digest tools/install-typst.sh pins"
    echo "typst-digests: $name of typst $version matches its pin"
done
