#!/bin/sh
# legend-gap.sh — a brief's legend keeps its note apart from its chips, by the gap header() keeps
# between its title and its meta, however long the note.
#
#   sh .github/legend-gap.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/legend-gap.typ
# sets a legend whose note's last word is pushed right by a box as wide as it is given. Built
# with none, the space between the note and its chip says how far the note can grow; it is then
# built pushed a point further each time, from 12pt short of that to 1pt past it, so the note's
# end comes to every distance from the chip, on one line and then wrapped. Each time, the chip's
# word must be a word of its own, and every word of the note must end at least that gap short of
# it.
set -eu
cd "$(dirname "$0")/.."
. .github/word-box.sh

fail() { echo "legend-gap: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

gap=$(sed -n 's/^#let _sides-gap = \([0-9.]*\)pt$/\1/p' lib/parts.typ)
[ -n "$gap" ] || fail "lib/parts.typ sets no _sides-gap in points"

# build <push>: the legend with its note's last word pushed that far; prints the space between
# the note and the chip, in points, then "one" or "wrapped".
build() {
    typst compile --root . --font-path fonts --ignore-system-fonts --input "push=$1" \
        .github/legend-gap.typ "$tmp/legend.pdf"
    pdftotext -bbox "$tmp/legend.pdf" "$tmp/legend.html"
    chip=$(word_box "$tmp/legend.html" Chipword)
    [ -n "$chip" ] || fail "pushed ${1}pt, Chipword is not a word of its own: the note runs into it"
    first=$(word_box "$tmp/legend.html" Colour)
    last=$(word_box "$tmp/legend.html" Noteend)
    [ -n "$first" ] && [ -n "$last" ] || fail "pushed ${1}pt, the note is not on the page"
    # Every word from the note's first line to its last, left of the chip: the note's.
    awk -v c="$chip" -v f="$first" -v l="$last" '
        function attr(k) {
            match($0, k "=\"[0-9.]+\"")
            return substr($0, RSTART + length(k) + 2, RLENGTH - length(k) - 3) + 0
        }
        BEGIN { split(c, cb, " "); split(f, fb, " "); split(l, lb, " "); end = -1 }
        /<word / {
            if (attr("yMin") >= fb[2] - 1 && attr("yMax") <= lb[4] + 1 && attr("xMax") <= cb[1])
                if (attr("xMax") > end) end = attr("xMax")
        }
        END { printf "%.2f %s\n", cb[1] - end, (lb[2] > fb[2] + 1) ? "wrapped" : "one" }
    ' "$tmp/legend.html"
}

r=$(build 0)
[ "${r#* }" = one ] || fail "unpushed, the note wraps"
room=${r% *}
one=0 wrapped=0
for step in 12 11 10 9 8 7 6 5 4 3 2 1 0 -1; do
    push=$(awk -v r="$room" -v s="$step" 'BEGIN { printf "%.2f", r - s }')
    r=$(build "$push")
    space=${r% *} how=${r#* }
    case $how in
        one) one=$((one + 1)) where="on one line" ;;
        *) wrapped=$((wrapped + 1)) where=wrapped ;;
    esac
    if awk -v s="$space" -v g="$gap" 'BEGIN { exit !(s < g - 0.1) }'; then
        fail "pushed ${push}pt, the note, $where, ends ${space}pt short of the chip, under ${gap}pt"
    fi
done
[ "$one" -gt 0 ] || fail "the note wraps however little it is pushed: none is on one line"
[ "$wrapped" -gt 0 ] || fail "the note wraps however far it is pushed: none is too long for one"
echo "legend-gap: a brief's legend keeps its note ${gap}pt or more from its chips, however long"
