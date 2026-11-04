#!/bin/sh
# addendum-size.sh — an addendum's label is sz.fine, or the size of the text around it where
# that is smaller: in a sheet's cell it is the size of the entry it is under, never larger.
#
#   sh .github/addendum-size.sh
#
# Run by CI's audit job and the oldest-toolchain job, which have poppler. A word's box in
# pdftotext is as tall as its size sets it, so each label is read against its entry: in a sheet,
# at sz.micro, the same height; in body text, at sz.small, sz.fine's, which is shorter.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "addendum-size: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/addendum-size.typ "$tmp/probe.pdf"
pdftotext -bbox "$tmp/probe.pdf" "$tmp/boxes.html"
. .github/word-box.sh
# height_of <word>: its box's height, to two places.
height_of() { word_box "$tmp/boxes.html" "$1" | awk '{ printf "%.2f\n", $4 - $2 }'; }
entry=$(height_of Sheetentry) label=$(height_of Sheetlabel)
[ -n "$entry" ] && [ -n "$label" ] || fail "the sheet's entry or its addendum is missing"
[ "$label" = "$entry" ] || fail "in a sheet, the label is ${label}pt tall and its entry ${entry}pt"
body=$(height_of Bodyentry) label=$(height_of Bodylabel)
[ -n "$body" ] && [ -n "$label" ] || fail "the body text's entry or its addendum is missing"
awk -v l="$label" -v b="$body" 'BEGIN { exit !(l < b) }' ||
    fail "in body text, the label is ${label}pt tall, no shorter than the text's ${body}pt"
echo "addendum-size: an addendum's label is no larger than the entry it is under"
