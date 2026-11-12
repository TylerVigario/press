#!/bin/sh
# sheet-spans.sh — a sheet sets typst's own table parts as typst's table does: a cell spanning
# columns or rows, a line and a footer.
#
#   sh .github/sheet-spans.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. On page 1 of
# .github/sheet-spans.typ, each word must stand under the heading of the column it is placed
# in, the footer's under the last row, and typst must warn of nothing a sheet dropped. On page 2, a
# sheet across two columns, the two rows a span ties together must stay in one column.
set -eu
cd "$(dirname "$0")/.."
. .github/word-box.sh

fail() { echo "sheet-spans: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/sheet-spans.typ \
    "$tmp/probe.pdf" 2> "$tmp/log" || { cat "$tmp/log" >&2; fail "the sheets do not compile"; }
pdftotext -f 1 -l 1 -bbox "$tmp/probe.pdf" "$tmp/one.html"
pdftotext -f 2 -l 2 -bbox "$tmp/probe.pdf" "$tmp/two.html"

# x <boxes> <word>: where the word starts across the page; y: where it starts down it.
x() { word_box "$1" "$2" | awk '{print $1}'; }
y() { word_box "$1" "$2" | awk '{print $2}'; }
# under <word> <heading>: the word starts where its column's heading does, within a point.
under() {
    w=$(x "$tmp/one.html" "$1"); h=$(x "$tmp/one.html" "$2")
    [ -n "$w" ] || fail "\"$1\" is not on the page"
    awk -v w="$w" -v h="$h" 'BEGIN { d = w - h; exit !(d < 1 && d > -1) }' \
        || fail "\"$1\" starts at x $w, not under $2 at x $h"
}
under Spanned Itemhead
under Firstnote Notehead
under Nuts Itemhead
under Twelve Amounthead
under Smallnote Notehead
under Thirty Amounthead
under Largenote Notehead
under Totalrow Itemhead
under Footnote Notehead
awk -v f="$(y "$tmp/one.html" Totalrow)" -v l="$(y "$tmp/one.html" Largenote)" \
    'BEGIN { exit !(f > l) }' || fail "the footer is not under the last row"
[ ! -s "$tmp/log" ] || { cat "$tmp/log" >&2; fail "typst warned of what a sheet was given"; }

# Page 2: Tieda and Tiedb, the two rows Tied spans, in the same column as Tied.
half=$(pdfinfo -f 2 -l 2 "$tmp/probe.pdf" | sed -n 's/^Page *2 size: *\([0-9.]*\) .*/\1/p' \
    | awk '{print $1 / 2}')
column() { x "$tmp/two.html" "$1" | awk -v h="$half" '{print ($1 < h ? "first" : "second")}'; }
for w in Tied Tieda Tiedb; do
    [ -n "$(x "$tmp/two.html" "$w")" ] || fail "\"$w\" is not on page 2"
done
[ "$(column Tied)" = "$(column Tieda)" ] && [ "$(column Tied)" = "$(column Tiedb)" ] \
    || fail "a span's rows are split between columns: Tied in the $(column Tied), Tieda in the" \
        "$(column Tieda), Tiedb in the $(column Tiedb)"
echo "sheet-spans: a sheet sets a span, a line and a footer as typst's table does"
