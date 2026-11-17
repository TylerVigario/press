#!/bin/sh
# units-order.sh — units(pack: "stacks") keeps its units in the order given, down the left column
# and then the right, split where the two come out most level.
#
#   sh .github/units-order.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. "stacks" once put each
# unit in whichever column was shorter, so a long unit first and five short ones read First,
# Fifth, Second, Third, Fourth, Sixth, on paper and in the PDF's text alike. .github/units-order.typ
# sets a long unit first and five short ones, five short ones and a long one last, three alike,
# and the first again 1em apart: in each, the PDF's text must read the units in order, and the
# left column must hold the first of them, as many as bring the columns most nearly level, the
# left the longer where two splits are as level.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "units-order: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Each case, its number of units, and the units its left column must hold.
for c in long-first:6:'1 2' long-last:6:'1 2 3 4' alike:3:'1 2' em:6:'1 2'; do
    case=${c%%:*} rest=${c#*:}
    n=${rest%%:*} want=${rest#*:}
    typst compile --root . --font-path fonts --ignore-system-fonts --input "case=$case" \
        .github/units-order.typ "$tmp/$case.pdf"
    got=$(pdftotext -raw "$tmp/$case.pdf" - | sed -n 's/^Unit \([0-9][0-9]*\).*/\1/p' | tr '\n' ' ')
    [ "$got" = "$(seq -s ' ' 1 "$n") " ] || fail "$case: the PDF's text reads the units $got"
    # Each unit's number and left edge, from its lead's two words, "Unit" and the number.
    pdftotext -bbox "$tmp/$case.pdf" - | awk '
        /<word / {
            w = $0; sub(/.*">/, "", w); sub(/<\/word>.*/, "", w)
            x = $0; sub(/.*xMin="/, "", x); sub(/".*/, "", x)
            if (lead && w ~ /^[0-9]+$/) print w, ux
            lead = (w == "Unit"); ux = x
        }' | sort -n > "$tmp/$case.at"
    edge=$(awk '$1 == 1 { print $2 }' "$tmp/$case.at")
    [ -n "$edge" ] || fail "$case: no Unit 1 on the page"
    left=$(awk -v e="$edge" '$2 == e { printf "%s%s", s, $1; s = " " }' "$tmp/$case.at")
    [ "$left" = "$want" ] || fail "$case: the left column holds units $left, not $want"
done
echo "units-order: \"stacks\" keeps its units in order, down the left column and then the right, split most level"
