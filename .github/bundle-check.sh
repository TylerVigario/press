#!/bin/sh
# bundle-check.sh — the release bundle holds the kit, installs as the README says, and works.
#
#   sh .github/bundle-check.sh <dir holding press.tar.gz, press.zip and SHA256SUMS>
#
# Run by CI on every pull request, on what .github/bundle.sh just built:
#
#   · the sums match, and both archives hold the same files;
#   · nothing of press's own machinery is in them, and every file the kit needs is;
#   · a scratch repo installs the tarball the way the README's one-liner does, streamed into
#     tar in the directory it should land in, and the zip unpacks to the same files;
#   · in that repo, with no just: new.sh scaffolds a document, stamp.sh builds it, check.sh
#     audits it clean, plain typst builds it from environment variables, and the calibration
#     sheet builds and audits clean from inside the installed kit.
set -eu

b=$(cd "${1:?usage: sh .github/bundle-check.sh <bundle dir>}" && pwd)
fail() { echo "bundle-check: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

(cd "$b" && sha256sum -c --quiet SHA256SUMS) || fail "SHA256SUMS does not match the archives"

tar -tzf "$b/press.tar.gz" | sed 's#/$##' | LC_ALL=C sort > "$tmp/tar.list"
unzip -Z1 "$b/press.zip" | sed 's#/$##' | LC_ALL=C sort > "$tmp/zip.list"
cmp -s "$tmp/tar.list" "$tmp/zip.list" || { diff "$tmp/tar.list" "$tmp/zip.list" >&2; fail "the archives hold different files"; }

for f in .github CLAUDE.md CHANGELOG.md cog.toml justfile .gitignore; do
    ! grep -qx "press/$f" "$tmp/tar.list" || fail "press/$f is in the bundle; it is press's own machinery"
done
for f in lib.typ press.toml template/main.typ calibration.typ press.just README.md FONTS.md LICENSE \
         tools/new.sh tools/stamp.sh tools/check.sh tools/report.sh fonts/licenses; do
    grep -qx "press/$f" "$tmp/tar.list" || fail "press/$f is missing from the bundle"
done

repo="$tmp/repo"
mkdir -p "$repo/vendor"
(cd "$repo/vendor" && tar -xz < "$b/press.tar.gz")
mkdir -p "$tmp/zip"
(cd "$tmp/zip" && unzip -q "$b/press.zip")
diff -r "$repo/vendor/press" "$tmp/zip/press" >/dev/null || fail "the zip unpacks to different files than the tarball"

cd "$repo"
flags="--root . --font-path vendor/press/fonts --ignore-system-fonts"
sh vendor/press/tools/new.sh docs/guide
# shellcheck disable=SC2086  # $flags is a list of flags
sh vendor/press/tools/stamp.sh docs/guide/main.typ print/guide.pdf $flags
# shellcheck disable=SC2086
sh vendor/press/tools/check.sh docs/guide/main.typ print/guide.pdf vendor/press $flags
TYPST_ROOT=. TYPST_FONT_PATHS=vendor/press/fonts TYPST_IGNORE_SYSTEM_FONTS=true \
    typst compile docs/guide/main.typ print/plain.pdf
# shellcheck disable=SC2086
sh vendor/press/tools/stamp.sh vendor/press/calibration.typ print/calibration.pdf $flags
# shellcheck disable=SC2086
sh vendor/press/tools/check.sh vendor/press/calibration.typ print/calibration.pdf vendor/press $flags
echo "bundle-check: the bundle installs and works, version $(sed -n 's/^version *= *"\(.*\)"$/\1/p' vendor/press/press.toml)"
