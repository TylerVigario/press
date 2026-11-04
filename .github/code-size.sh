#!/bin/sh
# code-size.sh — inline code is set to the text around it: sz.fine in body text, a sheet's own
# size in its cells, a step below a larger text, and a document's own rule for raw still wins.
#
#   sh .github/code-size.sh
#
# Run by CI's audit job and the oldest-toolchain job, which have poppler. Every glyph of
# Liberation Mono is 0.6em wide, so a word of code's width in pdftotext's boxes gives its size.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "code-size: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/code-size.typ "$tmp/probe.pdf"
pdftotext -bbox "$tmp/probe.pdf" "$tmp/boxes.html"
# size_of <word>: the size in points its box's width gives, to two places.
size_of() {
    awk -v w="$1" '
        index($0, ">" w "<") {
            match($0, /xMin="[0-9.]+"/); x0 = substr($0, RSTART + 6, RLENGTH - 7)
            match($0, /xMax="[0-9.]+"/); x1 = substr($0, RSTART + 6, RLENGTH - 7)
            printf "%.2f\n", (x1 - x0) / (0.6 * length(w)); exit
        }' "$tmp/boxes.html"
}
for case in "codebody:9.40:in body text" "codesheet:8.60:in a sheet's cell" \
            "codesheetsmall:10.20:in a sheet at sz.small" "codelead:11.52:in a lead at sz.lead" \
            "codeown:12.00:under the document's own rule"; do
    word=${case%%:*} rest=${case#*:}
    want=${rest%%:*} where=${rest#*:}
    got=$(size_of "$word")
    [ -n "$got" ] || fail "\"$word\" is on no page"
    [ "$got" = "$want" ] || fail "code $where is ${got}pt, not ${want}pt"
done
echo "code-size: inline code is set to the text around it, and a document's own rule wins"
