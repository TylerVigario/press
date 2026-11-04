#!/bin/sh
# stamp-break.sh — a stamp's hairline never ends a page apart from its words.
#
#   sh .github/stamp-break.sh
#
# Run by CI's audit job and the oldest-toolchain job. A stamp is a hairline and the words under
# it, and the hairline is a sticky block, which typst keeps with what follows it.
# .github/stamp-break.typ starts a stamp where its hairline fits at the foot of a page and its
# first line does not. The hairline is not text, so the probe is drawn twice, once with a page
# break before the stamp, and each page must come out the same: the stamp left nothing behind.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "stamp-break: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for at in no yes; do
    mkdir "$tmp/$at"
    typst compile --root . --font-path fonts --ignore-system-fonts --input "break=$at" \
        .github/stamp-break.typ "$tmp/$at/{p}.png"
done
[ -f "$tmp/no/2.png" ] && [ ! -f "$tmp/no/3.png" ] || fail "the probe should print on 2 pages"
for page in 1 2; do
    cmp -s "$tmp/no/$page.png" "$tmp/yes/$page.png" ||
        fail "page $page differs from the stamp set after a page break: its hairline ends page 1"
done
echo "stamp-break: a stamp's hairline stays on the page with its words"
