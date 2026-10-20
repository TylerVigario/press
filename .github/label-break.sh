#!/bin/sh
# label-break.sh — a callout's, a panel's or a unit's label never ends a page apart from what it
# heads.
#
#   sh .github/label-break.sh
#
# Run by CI's audit job and the oldest-toolchain job, which have poppler. Each of these parts is
# one block that may break across a page, and typst would break it straight after its label as
# readily as anywhere else; the label is a sticky block, which typst keeps with what follows it.
# .github/label-break.typ starts each part where its label fits at the foot of a page and the line
# under it does not, so the label must open the next page with that line.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "label-break: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/label-break.typ "$tmp/probe.pdf"
pages=$(pdfinfo "$tmp/probe.pdf" | sed -n 's/^Pages: *//p')
# page_of <text>: the page the text prints on. Spaces are dropped before matching, since
# pdftotext reads a tracked label's letters with spaces between some of them.
page_of() {
    p=1
    while [ "$p" -le "$pages" ]; do
        pdftotext -f "$p" -l "$p" "$tmp/probe.pdf" - | tr -d ' \n' | grep -qF "$1" && { echo "$p"; return; }
        p=$((p + 1))
    done
    fail "\"$1\" is on no page"
}
for part in "callout:CALLOUTLABEL:Calloutbodybegins" "panel:PANELLABEL:Panelbodybegins" \
            "unit:UNITLABEL:Unitleadbegins"; do
    name=${part%%:*} rest=${part#*:}
    label=$(page_of "${rest%%:*}")
    under=$(page_of "${rest#*:}")
    [ "$label" = "$under" ] || fail "the $name's label ends page $label, and what it heads starts page $under"
done
echo "label-break: a callout's, a panel's and a unit's label stay on the page with what they head"
