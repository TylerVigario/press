#!/bin/sh
# bundle.sh — build the release bundle: the kit a repo holds, none of press's machinery, and
# the installers that fetch it.
#
#   sh .github/bundle.sh <out dir>
#
# Writes into <out dir>:
#
#   press.tar.gz, press.zip  each holding press/ with exactly the files below;
#   install.sh, install.ps1  the installers, with press.toml's version and their archive's
#                            SHA-256 written in, so each release's installer installs that
#                            release and refuses any other bytes;
#   SHA256SUMS               all four.
#
# The release attaches all five; CI builds them on every pull request, installs the kit into a
# scratch repo (.github/bundle-check.sh) and runs the installers (.github/install-check.sh).
#
# An ALLOWLIST, not the tree minus exclusions: a file press adds to its own machinery
# (.github/, CLAUDE.md, the changelog) stays out without anyone remembering to leave it out,
# and a file the kit needs is added here on purpose.
#
# Reproducible: every file carries one commit's time, names are sorted and owners zeroed, so
# a release's tag always yields the bytes it published, and its sums can be rebuilt and
# compared. The time is the newest commit's that is not a release's own. The release run
# builds the bundle before the forge records its `release:` commit, so a rebuild from the tag
# skips that commit to reach the same time.
set -eu
cd "$(dirname "$0")/.."

out=${1:?usage: sh .github/bundle.sh <out dir>}
version=$(sed -n 's/^version *= *"\(.*\)"$/\1/p' press.toml)
[ -n "$version" ] || { echo "bundle: press.toml has no version line" >&2; exit 1; }
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

when=$(git log -1 --format=%ct --invert-grep --grep='^release: v' 2>/dev/null || date +%s)
# A clone holding only a release's own commit, as `git clone --depth 1 --branch v<version>`
# makes, has no commit to take the time from, and its bytes could not be the published ones.
[ -n "$when" ] || { echo "bundle: HEAD is a release's own commit and the history stops there;" >&2
                    echo "        fetch the commit before it (git fetch --deepen 1) and run this again" >&2
                    exit 1; }
find "$tmp/press" -exec touch -h -d "@$when" {} +

mkdir -p "$out"
out=$(cd "$out" && pwd)
(cd "$tmp" && tar --sort=name --mtime="@$when" --owner=0 --group=0 --numeric-owner -cf - press \
    | gzip -n -9 > "$out/press.tar.gz")
rm -f "$out/press.zip"
(cd "$tmp" && find press | LC_ALL=C sort | TZ=UTC zip -q -X -@ "$out/press.zip")

# Each installer carries the sum of the archive it fetches: the tarball for sh, the zip for
# PowerShell.
for i in sh:press.tar.gz ps1:press.zip; do
    sum=$(sha256sum "$out/${i#*:}")
    sed -e "s/@VERSION@/$version/g" -e "s/@SHA256@/${sum%% *}/g" "install.${i%%:*}" > "$out/install.${i%%:*}"
    ! grep -q '@VERSION@\|@SHA256@' "$out/install.${i%%:*}" \
        || { echo "bundle: install.${i%%:*} still has a placeholder" >&2; exit 1; }
done
(cd "$out" && sha256sum press.tar.gz press.zip install.sh install.ps1 > SHA256SUMS)
echo "bundle: $out/press.tar.gz, press.zip, install.sh, install.ps1, SHA256SUMS (press $version)"
