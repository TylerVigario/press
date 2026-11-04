#!/bin/sh
# code-size.sh — inline code is set to the text around it: sz.fine in body text, a sheet's own
# size in its cells, a step below a larger text, and a document's own rule for raw still wins.
# Every template sets it so, in press's mono face rather than typst's own, and boxes a code block
# with code().
#
#   sh .github/code-size.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. Every glyph of
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
. .github/word-box.sh
# size_of <word>: the size in points its box's width gives, to two places.
size_of() {
    word_box "$tmp/boxes.html" "$1" | awk -v n="${#1}" '{ printf "%.2f\n", ($3 - $1) / (0.6 * n) }'
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
# left_of <word>: the left edge of its box, in points from the page's.
left_of() { word_box "$tmp/boxes.html" "$1" | awk '{ print $1 }'; }
# Under each template: the PDF embeds Liberation Mono and not typst's DejaVu Sans Mono, which
# the audit refuses, body code is a step below the template's body size, 10.2pt in all but
# letter, whose body is 11pt, and a code block is boxed by code(), its words 7pt in from the
# text's edge by its inset.
for case in brief:9.40 base:9.40 recipe:9.40 letter:10.14 resume:9.40; do
    template=${case%%:*} want=${case#*:}
    typst compile --root . --font-path fonts --ignore-system-fonts --input "template=$template" \
        .github/code-face.typ "$tmp/face.pdf"
    fonts=$(pdffonts "$tmp/face.pdf")
    printf '%s\n' "$fonts" | grep -q 'LiberationMono' || fail "$template sets code in no Liberation Mono"
    ! printf '%s\n' "$fonts" | grep -q 'DejaVu' || fail "$template sets code in typst's DejaVu Sans Mono"
    pdftotext -bbox "$tmp/face.pdf" "$tmp/boxes.html"
    got=$(size_of codeface)
    [ "$got" = "$want" ] || fail "$template sets body code at ${got}pt, not ${want}pt"
    text=$(left_of In) block=$(left_of codeblock)
    [ -n "$text" ] && [ -n "$block" ] ||
        fail "$template: the body text or the code block is missing"
    inset=$(awk -v a="$text" -v b="$block" 'BEGIN { printf "%.2f", b - a }')
    [ "$inset" = "7.00" ] ||
        fail "$template sets a code block ${inset}pt in from the text, not boxed by code()"
done
echo "code-size: inline code is set to the text around it, and a document's own rule wins"
echo "code-size: every template sets code in press's mono face, a step below its body text, and boxes a code block"
