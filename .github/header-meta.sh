#!/bin/sh
# header-meta.sh — header() keeps a title that fits on one line on it, with its meta wrapping
# beside it, and beside a title too long for one line, keeps a meta that fits in half the line on
# one line.
#
#   sh .github/header-meta.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/header-meta.typ
# sets the title and meta it is given: a long title must leave a short meta its one line; a
# title wider than half the line but short enough for one keeps it beside a long meta; two short
# ones stand at the line's two ends; and two long ones share the line in halves.
set -eu
cd "$(dirname "$0")/.."
. .github/word-box.sh

fail() { echo "header-meta: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

long_title="Titleone Titletwo Titlethree Titlefour Titlefive Titlesix Titleseven"
long_meta="Metaone Metatwo Metathree Metafour Metafive Metasix Metaseven Metaeight Metanine"
long_meta="$long_meta Metaten Metaeleven Metatwelve Metathirteen Metafourteen Metafifteen"
# build <name> <title> <meta>: the header, and its words' boxes in $tmp/<name>.html.
build() {
    typst compile --root . --font-path fonts --ignore-system-fonts --input "title=$2" \
        --input "meta=$3" .github/header-meta.typ "$tmp/$1.pdf"
    pdftotext -bbox "$tmp/$1.pdf" "$tmp/$1.html"
}
# lines <name> <words...>: how many lines the words are set on, by their tops.
lines() {
    f=$1; shift
    for w in "$@"; do
        b=$(word_box "$tmp/$f.html" "$w")
        [ -n "$b" ] || fail "\"$w\" is not on the page"
        echo "$b" | awk '{printf "%.0f\n", $2}'
    done | sort -u | wc -l | tr -d ' '
}

build issue "$long_title" "Metaone Metatwo Metathree"
n=$(lines issue Metaone Metatwo Metathree)
[ "$n" -eq 1 ] || fail "beside a long title, a short meta is set on $n lines, not one"
[ "$(lines issue Titleone Titleseven)" -gt 1 ] || fail "the long title does not wrap"

build meta "Titleone Titletwo Titlethree" "$long_meta"
n=$(lines meta Titleone Titletwo Titlethree)
[ "$n" -eq 1 ] || fail "beside a long meta, a title that fits on one line is set on $n lines"
half=$(pdfinfo "$tmp/meta.pdf" | sed -n 's/^Page size: *\([0-9.]*\) .*/\1/p' \
    | awk '{print ($1 - 72) / 2 + 36}')
wide=$(word_box "$tmp/meta.html" Titlethree | awk '{print $3}')
awk -v w="$wide" -v h="$half" 'BEGIN { exit !(w > h) }' \
    || fail "the title, meant to be wider than half the line, ends at x $wide, short of $half"
[ "$(lines meta Metaone Metafifteen)" -gt 1 ] || fail "the long meta does not wrap"

build short "Titleone Titletwo" "Metaone Metatwo"
right=$(pdfinfo "$tmp/short.pdf" | sed -n 's/^Page size: *\([0-9.]*\) .*/\1/p' \
    | awk '{print $1 - 36}')
end=$(word_box "$tmp/short.html" Metatwo | awk '{print $3}')
awk -v e="$end" -v r="$right" 'BEGIN { d = r - e; exit !(d < 1 && d > -1) }' \
    || fail "a short meta ends at x $end, not at the right margin, $right"

build both "$long_title" "$long_meta"
mid=$(pdfinfo "$tmp/both.pdf" | sed -n 's/^Page size: *\([0-9.]*\) .*/\1/p' | awk '{print $1 / 2}')
title_end=$(word_boxes "$tmp/both.html" Titlefive | awk '{print $3}' | head -n 1)
meta_start=$(word_boxes "$tmp/both.html" Metaone | awk '{print $1}' | head -n 1)
awk -v t="$title_end" -v m="$meta_start" -v h="$mid" 'BEGIN { exit !(t < h && m > h) }' \
    || fail "two long ones do not share the line in halves: the title reaches x $title_end," \
        "the meta starts at x $meta_start, the middle is $mid"
echo "header-meta: header() keeps a short title or meta on one line beside a long one"
