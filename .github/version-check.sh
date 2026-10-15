#!/bin/sh
# version-check.sh — press.toml's version is the one the last release wrote.
#
#   sh .github/version-check.sh
#
# Run by CI on every pull request and by the Release workflow before it decides. Only the
# release writes press.toml's version, so it is the newest release tag's, or a release's own
# commit recorded it and its publish has not happened yet, which the Release workflow then
# finishes at that number. Any other version is a hand edit: the Release workflow would take it
# for an unfinished release and publish it without the commits deriving it. Needs the history
# and the tags (fetch-depth: 0).
set -eu
cd "$(dirname "$0")/.."

fail() { echo "version-check: $*" >&2; exit 1; }
semver='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
v=$(sed -n 's/^version *= *"\(.*\)"$/\1/p' press.toml)
echo "$v" | grep -qE "$semver" || fail "press.toml has no version line a release can rewrite"
newest=$(git tag --list 'v*' | sed 's/^v//' | { grep -E "$semver" || true; } | sort -V | tail -n 1)
if [ -z "$newest" ]; then
    echo "version-check: no release yet; press.toml says $v"
    exit 0
fi
if [ "$v" = "$newest" ]; then
    echo "version-check: press.toml says $v, the newest release"
    exit 0
fi
wrote=$(git log -1 --format=%s -G '^version *=' -- press.toml)
[ "$wrote" = "release: v$v" ] \
    || fail "press.toml says $v, the newest release is $newest, and the commit that wrote $v is
       \"$wrote\", not the release's own; only the Release workflow writes the version"
echo "version-check: press.toml says $v, recorded by its release's commit and not yet published"
