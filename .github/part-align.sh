#!/bin/sh
# part-align.sh — inside a part's body, a flow is centred on the body and a line aligned right ends
# at its edge, as outside a part each is on the column.
#
#   sh .github/part-align.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. typst aligns a thing within
# the block it is in, and a block given no width is only as wide as its widest line, so a flow under
# a short line would sit at the part's left edge. In the body of each part a document writes one
# in, callout(), panel(), unit(), item(), decision() and addendum(), .github/part-align.typ sets a
# short line, a flow and a line aligned right. The line aligned right must end within a part's
# inset of the column's right edge, read from a line aligned right outside any part; and the flow
# must be centred between the body's left edge, where the short line starts, and that end.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "part-align: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

. .github/word-box.sh
typst compile --root . --font-path fonts --ignore-system-fonts .github/part-align.typ "$tmp/probe.pdf"
pdftotext -bbox "$tmp/probe.pdf" "$tmp/boxes.html"
column=$(word_box "$tmp/boxes.html" Columnend | awk '{ print $3 }')
[ -n "$column" ] || fail "the line aligned right outside any part is missing"
for part in Callout Panel Unit Item Decision Addendum; do
    name=$(printf '%s' "$part" | tr '[:upper:]' '[:lower:]')
    left=$(word_box "$tmp/boxes.html" "${part}left" | awk '{ print $1 }')
    mid=$(word_box "$tmp/boxes.html" "${part}mid" | awk '{ print ($1 + $3) / 2 }')
    end=$(word_box "$tmp/boxes.html" "${part}end" | awk '{ print $3 }')
    [ -n "$left" ] && [ -n "$mid" ] && [ -n "$end" ] || fail "${name}()'s body is missing"
    # A part's inset is 10pt at most, and the stroke at its edge under 1pt.
    awk -v end="$end" -v column="$column" 'BEGIN { exit !(end > column - 12) }' ||
        fail "in ${name}()'s body, a line aligned right ends at ${end}pt, short of the column's right edge at ${column}pt"
    awk -v l="$left" -v m="$mid" -v e="$end" 'BEGIN { d = m - (l + e) / 2; exit !(d < 1 && d > -1) }' ||
        fail "in ${name}()'s body, a flow is centred at ${mid}pt, not between its edges at ${left}pt and ${end}pt"
done
echo "part-align: inside each part's body, a flow is centred on the body and a line aligned right ends at its edge"
