#!/bin/sh
# bundle.sh — build the release bundle: the kit a repo holds, and none of press's machinery.
#
#   sh .github/bundle.sh <out dir>
#
# Writes press.tar.gz, press.zip and SHA256SUMS into <out dir>, each archive holding press/
# with exactly the files below. The release attaches all three; CI builds them on every pull
# request and installs them into a scratch repo (.github/bundle-check.sh).
#
# An ALLOWLIST, not the tree minus exclusions: a file press adds to its own machinery
# (.github/, CLAUDE.md, the changelog) stays out without anyone remembering to leave it out,
# and a file the kit needs is added here on purpose.
#
# Reproducible: every file carries the commit's time, names are sorted and owners zeroed, so
# one commit always yields the same bytes and the published sums can be rebuilt and compared.
set -eu
cd "$(dirname "$0")/.."

out=${1:?usage: sh .github/bundle.sh <out dir>}
kit="lib.typ press.toml template calibration.typ fonts tools press.just README.md FONTS.md LICENSE"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$tmp/press"
for f in $kit; do
    [ -e "$f" ] || { echo "bundle: $f is in the kit but not in the tree" >&2; exit 1; }
    cp -R "$f" "$tmp/press/"
done
# Leftovers a working tree can hold and a release must not.
find "$tmp/press" -name __pycache__ -prune -exec rm -rf {} +
find "$tmp/press" -name '*.pyc' -exec rm -f {} +

when=$(git log -1 --format=%ct 2>/dev/null || date +%s)
find "$tmp/press" -exec touch -h -d "@$when" {} +

mkdir -p "$out"
out=$(cd "$out" && pwd)
(cd "$tmp" && tar --sort=name --mtime="@$when" --owner=0 --group=0 --numeric-owner -cf - press \
    | gzip -n -9 > "$out/press.tar.gz")
rm -f "$out/press.zip"
(cd "$tmp" && find press | LC_ALL=C sort | TZ=UTC zip -q -X -@ "$out/press.zip")
(cd "$out" && sha256sum press.tar.gz press.zip > SHA256SUMS)
echo "bundle: $out/press.tar.gz, press.zip, SHA256SUMS"
