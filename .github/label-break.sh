#!/bin/sh
# label-break.sh — a callout's, a panel's or a unit's label never ends a page apart from what it
# heads.
#
#   sh .github/label-break.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. Each of these parts is
# one block that may break across a page, and typst would break it straight after its label as
# readily as anywhere else; the label is a sticky block, which typst keeps with what follows it.
# .github/label-break.typ starts each part where its label fits at the foot of a page and the line
# under it does not, so the label must open the next page with that line. Its spacers are sized by
# hand, so the probe is drawn again against a copy of lib with no label sticky, where each label
# must end its page: else a spacer no longer sets the part where it can, and the check above would
# pass whether the label is sticky or not.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "label-break: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/label-break.typ "$tmp/probe.pdf"
# The same probe against a copy of lib whose blocks are none of them sticky.
mkdir -p "$tmp/unstuck/.github"
cp -R lib lib.typ press.toml "$tmp/unstuck/"
cp .github/label-break.typ "$tmp/unstuck/.github/"
grep -q 'sticky: true' "$tmp"/unstuck/lib/*.typ || fail "lib has no sticky: true to take out"
for f in "$tmp"/unstuck/lib/*.typ; do
    sed 's/sticky: true/sticky: false/g' "$f" > "$f.new" && mv "$f.new" "$f"
done
typst compile --root "$tmp/unstuck" --font-path fonts --ignore-system-fonts \
    "$tmp/unstuck/.github/label-break.typ" "$tmp/unstuck.pdf"
# page_of <pdf> <text>: the page the text prints on. Spaces are dropped before matching, since
# pdftotext reads a tracked label's letters with spaces between some of them.
page_of() {
    pages=$(pdfinfo "$1" | sed -n 's/^Pages: *//p')
    p=1
    while [ "$p" -le "$pages" ]; do
        pdftotext -f "$p" -l "$p" "$1" - | tr -d ' \n' | grep -qF "$2" && { echo "$p"; return; }
        p=$((p + 1))
    done
    fail "\"$2\" is on no page"
}
for part in "callout:CALLOUTLABEL:Calloutbodybegins" "panel:PANELLABEL:Panelbodybegins" \
            "unit:UNITLABEL:Unitleadbegins"; do
    name=${part%%:*} rest=${part#*:}
    label=$(page_of "$tmp/unstuck.pdf" "${rest%%:*}")
    under=$(page_of "$tmp/unstuck.pdf" "${rest#*:}")
    [ "$label" != "$under" ] || fail "with no label sticky, the $name's label still opens page" \
        "$label with what it heads: its spacer no longer sets it at a page's foot; resize it"
    label=$(page_of "$tmp/probe.pdf" "${rest%%:*}")
    under=$(page_of "$tmp/probe.pdf" "${rest#*:}")
    [ "$label" = "$under" ] || fail "the $name's label ends page $label, and what it heads starts page $under"
done
echo "label-break: a callout's, a panel's and a unit's label stay on the page with what they head"
