#!/bin/sh
# sources.sh — src() numbers a source by its place in sources(), and the list prints each one's
# number, title and short address, its link whole.
#
#   sh .github/sources.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/sources.typ cites
# three sources in an order other than the one sources() gives them in, so each marker must carry
# the numbers of the list, not of the citing: [3], then [1, 3] for two named out of order, then
# [2]. A marker is set smaller than the text it is in. Each line of the list is its number and
# title, then the address without https://, and the source with no address prints no separator.
# Each link holds the whole address. A key no sources() gives, and one given twice, stop the build
# with a message naming the key.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "sources: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

. .github/word-box.sh
build() { typst compile --root . --font-path fonts --ignore-system-fonts "$@" .github/sources.typ "$tmp/probe.pdf"; }
build
pdftotext "$tmp/probe.pdf" "$tmp/text.txt"
text=$(tr '\n' ' ' < "$tmp/text.txt" | tr -s ' ')

for want in "cites the third first [3] alone" "named out of order [1, 3]" "with no address [2]" \
    "1. Alphasource title · example.org/alpha" "2. Betasource title 3." \
    "3. Gammasource title · www.example.org/gamma/a/long/path"; do
    case $text in *"$want"*) ;; *) fail "the page does not read \"$want\"; it reads: $text" ;; esac
done

pdfinfo -url "$tmp/probe.pdf" | awk 'NR > 1 { print $3 }' | sort > "$tmp/links"
printf '%s\n' https://example.org/alpha https://www.example.org/gamma/a/long/path > "$tmp/want"
cmp -s "$tmp/links" "$tmp/want" || fail "the links are not the whole addresses: $(tr '\n' ' ' < "$tmp/links")"

pdftotext -bbox "$tmp/probe.pdf" "$tmp/boxes.html"
height() { word_box "$tmp/boxes.html" "$1" | awk '{ print $4 - $2 }'; }
body=$(height Bodyword) mark=$(height "[3]")
[ -n "$body" ] && [ -n "$mark" ] || fail "the text or its first marker is missing"
awk -v b="$body" -v m="$mark" 'BEGIN { exit !(m < b * 0.85) }' ||
    fail "a marker is ${mark}pt tall, no smaller than the text's ${body}pt"

for case in "unknown:no sources() gives the key \"nosuch\"" "twice:the key \"alpha\" is given twice"; do
    rc=0
    build --input "case=${case%%:*}" 2> "$tmp/said" || rc=$?
    [ "$rc" != 0 ] || fail "case ${case%%:*} built; it must stop the build"
    grep -qF "${case#*:}" "$tmp/said" || fail "case ${case%%:*} does not say \"${case#*:}\": $(cat "$tmp/said")"
done
echo "sources: markers number by the list, each source prints short with its link whole, and a bad key stops the build"
