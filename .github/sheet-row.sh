#!/bin/sh
# sheet-row.sh — a sheet's row that does not fit in what is left of the page starts the next one
# whole, one taller than a page splits, and under breakable: true any row splits.
#
#   sh .github/sheet-row.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. typst splits a table's row
# at the page's foot unless the row is unbreakable, and the rest of it opens the next page beside
# empty cells, reading as a row with nothing in its first column. .github/sheet-row.typ starts a
# sheet where its first row fits at the foot of a page and its second does not, so that row must
# open the next page with its first column; then the same sheet with breakable: true, whose
# second row must begin on the first page and end on the next. Last, a sheet whose second row is
# taller than a page: kept whole, it would run off the page's foot, where its last words print on
# no page, so it must begin on one page and end on a later one.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "sheet-row: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/sheet-row.typ "$tmp/probe.pdf"
pages=$(pdfinfo "$tmp/probe.pdf" | sed -n 's/^Pages: *//p')
# page_of <text>: the page the text prints on, spaces dropped, as pdftotext breaks lines.
page_of() {
    p=1
    while [ "$p" -le "$pages" ]; do
        pdftotext -f "$p" -l "$p" "$tmp/probe.pdf" - | tr -d ' \n' | grep -qF "$1" && { echo "$p"; return; }
        p=$((p + 1))
    done
    fail "\"$1\" is on no page"
}
claim=$(page_of "Wholeclaim")
begins=$(page_of "Wholeevidencebegins")
ends=$(page_of "Wholeevidenceends")
short=$(page_of "Ashortclaim")
[ "$claim" = "$begins" ] && [ "$begins" = "$ends" ] \
    || fail "the row is split: its claim is on page $claim, its evidence on pages $begins to $ends"
[ "$claim" -gt "$short" ] || fail "the row did not need the next page, so this proves nothing: it is on page $claim"
claim=$(page_of "Splitclaim")
begins=$(page_of "Splitevidencebegins")
ends=$(page_of "Splitevidenceends")
[ "$claim" = "$begins" ] && [ "$ends" -gt "$begins" ] \
    || fail "under breakable: true the row is not split: it begins on page $begins and ends on page $ends"
claim=$(page_of "Tallclaim")
begins=$(page_of "Tallevidencebegins")
ends=$(page_of "Tallevidenceends")
[ "$claim" = "$begins" ] && [ "$ends" -gt "$begins" ] \
    || fail "a row taller than a page is not split: it begins on page $begins and ends on page $ends"
echo "sheet-row: a row that does not fit starts the next page whole, one taller than a page splits, and any splits under breakable: true"
