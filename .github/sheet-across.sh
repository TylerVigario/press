#!/bin/sh
# sheet-across.sh — a sheet set across columns reads down each column and then the next, and on
# the page where it ends, its rows are shared between the columns by their height.
#
#   sh .github/sheet-across.sh
#
# Run by CI's audit job and the oldest-toolchain job, which have poppler. typst flows a sheet's
# full pages through its columns, and press balances the last page by measuring every row, which
# depends on where the sheet starts on its page and on the page's margins. .github/sheet-across.typ
# holds two sheets: 120 rows that run onto a second page, which must read in order, with the
# second page's columns even; and eight rows whose first is as tall as several others, which must
# leave that column with fewer rows than the next, as a split by count would not.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "sheet-across: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/sheet-across.typ \
    "$tmp/probe.pdf"
# Half the page's width, in the points pdftotext crops by.
half=$(pdfinfo "$tmp/probe.pdf" | sed -n 's/^Page size: *\([0-9.]*\) .*/\1/p' \
    | awk '{print int($1 / 2)}')
# rows <page> <column>: the rows a column of a page prints, top to bottom, by their first word.
# An empty column prints none, which is a finding for the checks below, not an error here.
rows() {
    pdftotext -f "$1" -l "$1" -x $(($2 * half)) -y 0 -W "$half" -H 2000 "$tmp/probe.pdf" - \
        | grep -oE '^[RT][0-9]+' || true
}
count() { rows "$1" "$2" | wc -l | tr -d ' '; }

{ rows 1 0; rows 1 1; rows 2 0; rows 2 1; } > "$tmp/read"
seq 1 120 | sed 's/^/R/' > "$tmp/want"
cmp -s "$tmp/read" "$tmp/want" || {
    diff "$tmp/want" "$tmp/read" | head >&2
    fail "the sheet does not read down each column and then the next"
}
[ "$(count 1 1)" -gt 0 ] || fail "the first page's second column is empty"
l=$(count 2 0) r=$(count 2 1)
[ "$l" -ge "$r" ] && [ $((l - r)) -le 1 ] \
    || fail "the last page's columns hold $l and $r rows, where they should be even"
l=$(count 3 0) r=$(count 3 1)
[ "$l" -lt "$r" ] \
    || fail "with a tall first row, the columns hold $l and $r rows: split by count, not height"
echo "sheet-across: a sheet across columns reads in order, and its last page is shared by height"
