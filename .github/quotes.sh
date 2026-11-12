#!/bin/sh
# quotes.sh — a string's quotes print as markup's do, kerned as they are, and code, math and an
# address keep theirs straight.
#
#   sh .github/quotes.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. typst curls a quote typed
# in markup and sets one in a string as it is; every template curls a string's too. Each case of
# .github/quotes.typ is three lines that must print alike, word for word and each word where the
# others put it: its quotes typed curled, typed straight in markup, and given as a string. A rule
# that set the quote apart from its neighbours would lose the kerning beside it and move the words
# after it. The cases are prose, a tracked label, strings inside markup, a foot and an inch after a
# digit, and German. The title, given as a string, prints curled, and a quote in code, in math and
# in an address link-note prints, bare or in its footnote, stays straight. .github/quotes-each.typ
# gives a string under each template in turn, which must print its quote curled under all five.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "quotes: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/quotes.typ "$tmp/probe.pdf"
pdftotext "$tmp/probe.pdf" "$tmp/text.txt"
text=$(tr '\n' ' ' < "$tmp/text.txt" | tr -s ' ')

# Each labelled line is a row: its label, then each word after it with its left and right edges
# from the first one's left edge, so the lines compare wherever the label ends. z0 ends the cases.
pdftotext -bbox "$tmp/probe.pdf" "$tmp/boxes.html"
awk '/<word / {
    match($0, /xMin="[0-9.]+"/); x0 = substr($0, RSTART + 6, RLENGTH - 7)
    match($0, /xMax="[0-9.]+"/); x1 = substr($0, RSTART + 6, RLENGTH - 7)
    w = $0; sub(/^[^>]*>/, "", w); sub(/<\/word>.*/, "", w)
    if (w ~ /^[a-z][0-9]$/) { if (key != "") print key row; key = w; row = ""; first = ""; next }
    if (key == "" || key == "z0") next
    if (first == "") first = x0
    row = row sprintf(" %s:%.3f:%.3f", w, x0 - first, x1 - first)
} END { if (key != "" && key != "z0") print key row }' "$tmp/boxes.html" > "$tmp/rows"

row() { sed -n "s/^$1 //p" "$tmp/rows"; }
for case in k:prose t:"a tracked label" m:"strings inside markup" n:"a foot and an inch" g:German; do
    c=${case%%:*} curled=$(row "${c}1")
    [ -n "$curled" ] || fail "${case#*:}: the line typed curled is not on the page"
    for line in 2:"typed straight in markup" 3:"given as a string"; do
        got=$(row "$c${line%%:*}")
        [ "$got" = "$curled" ] || fail "${case#*:}, ${line#*:}, prints $got, where typed curled it prints $curled"
    done
done

for want in "The Tenant’s Notes" "echo 'it's' \"x\"" "grep 'it'\\''s' \"a file\"" "o'clock" \
    "example.org/bare'path" "example.org/foot'note"; do
    case $text in *"$want"*) ;; *) fail "the page does not read \"$want\"; it reads: $text" ;; esac
done
case $text in *"Tenant's"*) fail "the title prints a straight apostrophe: $text" ;; esac
for t in base brief letter recipe resume; do
    typst compile --root . --font-path fonts --ignore-system-fonts --input "template=$t" \
        .github/quotes-each.typ "$tmp/$t.pdf"
    each=$(pdftotext "$tmp/$t.pdf" - | tr '\n' ' ' | tr -s ' ')
    case $each in
        *"The tenant’s notes"*) ;;
        *) fail "under $t, a string's quote does not print curled; the page reads: $each" ;;
    esac
done
echo "quotes: a string's quotes print as markup's under every template, kerned alike, and code," \
    "math and an address keep theirs straight"
