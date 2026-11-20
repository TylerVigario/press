#!/bin/sh
# units-pages.sh — a group under "stacks" that runs past its page reads in the order given from
# page to page: each page's left column and then its right, the last page split between them.
#
#   sh .github/units-pages.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. Such a group was once one
# row of two columns broken across the page, so a page read the top of both columns before the
# rest of the left: six units read 1, 2, 4, 5, 3, 6. .github/units-pages.typ sets groups that run
# past their page, each unit starting "Unit" and its number and ending "Endmark" and the same.
# Read by where they are on the page, page by page, the left column and then the right, every
# unit's start and end must come in the order given; a unit that fits in a column must start and
# end in the same one, though typst's columns tell a part in the first page's right column that
# what is left of the page is all of it; the group must run onto a page after the one it starts
# on; and the units its last page starts must be in both its columns where there are two or more.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "units-pages: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Each case, its number of units, and the unit taller than a column, if any.
for c in plain:6: unit:6: tall:4:2 foot:5: deep:4: deep-plain:4: long:17: em:6: percent:6:; do
    case=${c%%:*} rest=${c#*:}
    n=${rest%%:*} tall=${rest#*:}
    typst compile --root . --font-path fonts --ignore-system-fonts --input "case=$case" \
        .github/units-pages.typ "$tmp/$case.pdf"
    # Each unit's start and end: its page, its column (0 the left, 1 the right), how far down,
    # "start" or "end", and its number; in the order a reader meets them.
    pdftotext -bbox "$tmp/$case.pdf" - | awk '
        function attr(k) {
            match($0, k "=\"[0-9.]+\"")
            return substr($0, RSTART + length(k) + 2, RLENGTH - length(k) - 3) + 0
        }
        /<page / { page++; mid = attr("width") / 2 }
        /<word / {
            w = $0; sub(/.*">/, "", w); sub(/<\/word>.*/, "", w)
            if ((prev == "Unit" || prev == "Endmark") && w ~ /^[0-9]+\.?$/) {
                sub(/\./, "", w)
                printf "%d %d %.2f %s %d\n", page, (attr("xMin") > mid), attr("yMin"),
                    (prev == "Unit" ? "start" : "end"), w
            }
            prev = w
        }' | sort -k1,1n -k2,2n -k3,3n > "$tmp/$case.at"
    got=$(awk '{ printf "%s%s %s", s, $4, $5; s = ", " }' "$tmp/$case.at")
    want=$(seq 1 "$n" | awk '{ printf "%sstart %d, end %d", s, $1, $1; s = ", " }')
    [ "$got" = "$want" ] || fail "$case: read page by page, the units come $got"
    # A unit that fits in a column starts and ends in the same one.
    split=$(awk -v tall="$tall" '
        $5 != tall && $4 == "start" { at[$5] = $1 " " $2 }
        $5 != tall && $4 == "end" && at[$5] != $1 " " $2 { print $5; exit }' "$tmp/$case.at")
    [ -z "$split" ] || fail "$case: unit $split fits in a column, and is split between two"
    first=$(awk 'NR == 1 { print $1 }' "$tmp/$case.at")
    last=$(awk 'END { print $1 }' "$tmp/$case.at")
    [ "$last" -gt "$first" ] || fail "$case: the group does not run past its page"
    # The units the last page starts, in its left column and in its right.
    sides=$(awk -v p="$last" '$1 == p && $4 == "start" { c[$2]++ }
        END { printf "%d %d", c[0], c[1] }' "$tmp/$case.at")
    left=${sides% *} right=${sides#* }
    if [ $((left + right)) -ge 2 ] && { [ "$left" -eq 0 ] || [ "$right" -eq 0 ]; }; then
        fail "$case: the last page starts $left units in its left column and $right in its right"
    fi
    echo "units-pages: $case reads in order over pages $first to $last"
done
echo "units-pages: a group under \"stacks\" past its page reads in order, from page to page"
