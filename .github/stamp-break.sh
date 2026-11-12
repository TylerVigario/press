#!/bin/sh
# stamp-break.sh — a stamp's hairline never ends a page apart from its words.
#
#   sh .github/stamp-break.sh
#
# Run by CI on press's typst and on the oldest toolchain. A stamp is a hairline and the words under
# it, and the hairline is a sticky block, which typst keeps with what follows it.
# .github/stamp-break.typ starts a stamp where its hairline fits at the foot of a page and its
# first line does not. The hairline is not text, so the probe is drawn twice, once with a page
# break before the stamp, and each page must come out the same: the stamp left nothing behind.
# Its spacer is sized by hand, so both are drawn again against a copy of lib with no block
# sticky, where the hairline must be left behind: else the spacer no longer sets the stamp where
# it can, and the check would pass whether the hairline is sticky or not.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "stamp-break: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# The same probe against a copy of lib whose blocks are none of them sticky.
mkdir -p "$tmp/unstuck/.github"
cp -R lib lib.typ press.toml "$tmp/unstuck/"
cp .github/stamp-break.typ "$tmp/unstuck/.github/"
grep -q 'sticky: true' "$tmp"/unstuck/lib/*.typ || fail "lib has no sticky: true to take out"
for f in "$tmp"/unstuck/lib/*.typ; do
    sed 's/sticky: true/sticky: false/g' "$f" > "$f.new" && mv "$f.new" "$f"
done
for at in no yes; do
    mkdir "$tmp/$at" "$tmp/unstuck-$at"
    typst compile --root . --font-path fonts --ignore-system-fonts --input "break=$at" \
        .github/stamp-break.typ "$tmp/$at/{p}.png"
    typst compile --root "$tmp/unstuck" --font-path fonts --ignore-system-fonts \
        --input "break=$at" "$tmp/unstuck/.github/stamp-break.typ" "$tmp/unstuck-$at/{p}.png"
done
! cmp -s "$tmp/unstuck-no/1.png" "$tmp/unstuck-yes/1.png" || fail "with no block sticky, the" \
    "stamp's hairline still opens page 2 with its words: the spacer no longer sets it at a" \
    "page's foot; resize it"
[ -f "$tmp/no/2.png" ] && [ ! -f "$tmp/no/3.png" ] || fail "the probe should print on 2 pages"
for page in 1 2; do
    cmp -s "$tmp/no/$page.png" "$tmp/yes/$page.png" ||
        fail "page $page differs from the stamp set after a page break: its hairline ends page 1"
done
echo "stamp-break: a stamp's hairline stays on the page with its words"
