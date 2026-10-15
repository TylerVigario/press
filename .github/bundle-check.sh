#!/bin/sh
# bundle-check.sh — the release bundle holds the kit, installs as the README says, and works.
#
#   sh .github/bundle-check.sh <dir holding what .github/bundle.sh built>
#
# Run by CI on every pull request, on what .github/bundle.sh just built:
#
#   · SHA256SUMS lists the two archives and the two installers, and they match it;
#   · each installer carries the archives' version and the sum of the archive it fetches;
#   · both archives hold the same files;
#   · nothing of press's own machinery is in them, and every file the kit needs is;
#   · a scratch repo installs the tarball the way the README's line without the installer
#     does, streamed into tar in the directory it should land in, and the zip unpacks to the
#     same files (the installers themselves are .github/install-check.sh's);
#   · in that repo, with no just: new.sh scaffolds a document and a letter, stamp.sh builds
#     them, check.sh audits them clean, plain typst builds the document from environment
#     variables, and the calibration sheet builds and audits clean from inside the installed kit.
set -eu

b=$(cd "${1:?usage: sh .github/bundle-check.sh <bundle dir>}" && pwd)
fail() { echo "bundle-check: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

(cd "$b" && sha256sum -c --quiet SHA256SUMS) || fail "SHA256SUMS does not match the files"
listed=$(awk '{ print $2 }' "$b/SHA256SUMS" | LC_ALL=C sort | tr '\n' ' ')
[ "$listed" = "install.ps1 install.sh press.tar.gz press.zip " ] || fail "SHA256SUMS lists $listed"

v=$(tar -xzOf "$b/press.tar.gz" press/press.toml | sed -n 's/^version *= *"\(.*\)"$/\1/p')
tgz=$(awk '$2 == "press.tar.gz" { print $1 }' "$b/SHA256SUMS")
zip=$(awk '$2 == "press.zip" { print $1 }' "$b/SHA256SUMS")
grep -qxF "    version='$v'" "$b/install.sh" || fail "install.sh does not install press $v"
grep -qxF "    sum='$tgz'" "$b/install.sh" || fail "install.sh does not carry the tarball's sum"
grep -qxF "    \$version = '$v'" "$b/install.ps1" || fail "install.ps1 does not install press $v"
grep -qxF "    \$sum = '$zip'" "$b/install.ps1" || fail "install.ps1 does not carry the zip's sum"

tar -tzf "$b/press.tar.gz" | sed 's#/$##' | LC_ALL=C sort > "$tmp/tar.list"
unzip -Z1 "$b/press.zip" | sed 's#/$##' | LC_ALL=C sort > "$tmp/zip.list"
cmp -s "$tmp/tar.list" "$tmp/zip.list" || { diff "$tmp/tar.list" "$tmp/zip.list" >&2; fail "the archives hold different files"; }

for f in .github CLAUDE.md CHANGELOG.md cog.toml justfile .markdownlint-cli2.jsonc; do
    ! grep -qx "press/$f" "$tmp/tar.list" || fail "press/$f is in the bundle; it is press's own machinery"
done
for f in lib.typ press.toml .gitignore template/main.typ template/letter.typ calibration.typ press.just README.md FONTS.md LICENSE \
         tools/new.sh tools/stamp.sh tools/check.sh tools/report.sh fonts/licenses; do
    grep -qx "press/$f" "$tmp/tar.list" || fail "press/$f is missing from the bundle"
done

repo="$tmp/repo"
mkdir -p "$repo/third_party"
(cd "$repo/third_party" && tar -xz < "$b/press.tar.gz")
mkdir -p "$tmp/zip"
(cd "$tmp/zip" && unzip -q "$b/press.zip")
diff -r "$repo/third_party/press" "$tmp/zip/press" >/dev/null || fail "the zip unpacks to different files than the tarball"

cd "$repo"
flags="--root . --font-path third_party/press/fonts --ignore-system-fonts"
sh third_party/press/tools/new.sh docs/guide
# shellcheck disable=SC2086  # $flags is a list of flags
sh third_party/press/tools/stamp.sh docs/guide/main.typ print/guide.pdf $flags
# shellcheck disable=SC2086
sh third_party/press/tools/check.sh docs/guide/main.typ print/guide.pdf third_party/press $flags
sh third_party/press/tools/new.sh docs/letter letter
# shellcheck disable=SC2086
sh third_party/press/tools/stamp.sh docs/letter/main.typ print/letter.pdf $flags
# shellcheck disable=SC2086
sh third_party/press/tools/check.sh docs/letter/main.typ print/letter.pdf third_party/press $flags
TYPST_ROOT=. TYPST_FONT_PATHS=third_party/press/fonts TYPST_IGNORE_SYSTEM_FONTS=true \
    typst compile docs/guide/main.typ print/plain.pdf
# shellcheck disable=SC2086
sh third_party/press/tools/stamp.sh third_party/press/calibration.typ print/calibration.pdf $flags
# shellcheck disable=SC2086
sh third_party/press/tools/check.sh third_party/press/calibration.typ print/calibration.pdf third_party/press $flags
echo "bundle-check: the bundle installs and works, version $(sed -n 's/^version *= *"\(.*\)"$/\1/p' third_party/press/press.toml)"
