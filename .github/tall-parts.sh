#!/bin/sh
# tall-parts.sh — under a template, a code block, unit, decision or item taller than a page breaks
# across pages and loses nothing, and one that fits on a page moves to the next whole.
#
#   sh .github/tall-parts.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. Each part is kept whole
# where it fits on a page, and let break where it is taller than one (breakable: auto). Kept
# whole, a part taller than a page runs off the page's foot, and its end prints on no page.
# .github/tall-parts.typ has one of each taller than a page: every line of the code, and the last
# words of the others, must be on a page, and the text after each too. Then a code block, a unit
# and an item, each too long for the room left on its page: each must start the next page whole.
# Built again with the short ones let break, each must split across that turn, which shows it
# meets one. A decision is not among them: typst moves its row whole where it fits a page, let
# break or not.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "tall-parts: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for b in auto true; do
    typst compile --root . --font-path fonts --ignore-system-fonts --input "breakable=$b" \
        .github/tall-parts.typ "$tmp/$b.pdf"
done
# page_of <pdf> <line>: the page a line prints on, or 0 for none.
page_of() {
    pages=$(pdfinfo "$1" | sed -n 's/^Pages: *//p')
    p=1
    while [ "$p" -le "$pages" ]; do
        pdftotext -f "$p" -l "$p" "$1" - | grep -qx " *$2" && { echo "$p"; return; }
        p=$((p + 1))
    done
    echo 0
}
pdf=$tmp/auto.pdf
n=$(pdftotext "$pdf" - | tr '\f' '\n' | grep -cx ' *echo tall [0-9]*' || true)
[ "$n" -eq 90 ] || fail "a code block taller than a page printed $n of its 90 lines"
for w in "the code:After the tall code." "a unit:Uends" "a unit:After the tall unit." \
        "a decision:Dends" "a decision:After the tall decision." "an item:Iends" \
        "an item:After the tall item."; do
    [ "$(page_of "$pdf" "${w#*:}")" -gt 0 ] \
        || fail "with ${w%%:*} taller than a page, \"${w#*:}\" is on no page"
done
for w in "code:CSstart:echo short 0:echo short 29" "unit:USstart:USbegins:USends" \
        "item:ISstart:ISbegins:ISends"; do
    part=${w%%:*}; w=${w#*:}; start=${w%%:*}; w=${w#*:}; first=${w%%:*}; last=${w#*:}
    s=$(page_of "$pdf" "$start"); a=$(page_of "$pdf" "$first"); z=$(page_of "$pdf" "$last")
    [ "$a" -eq $((s + 1)) ] && [ "$z" -eq "$a" ] \
        || fail "a short $part did not start the next page whole (pages $s, $a, $z)"
    s=$(page_of "$tmp/true.pdf" "$start"); a=$(page_of "$tmp/true.pdf" "$first")
    z=$(page_of "$tmp/true.pdf" "$last")
    [ "$a" -eq "$s" ] && [ "$z" -eq $((s + 1)) ] \
        || fail "a short $part let break did not split across the turn, so it meets none (pages $s, $a, $z)"
done
echo "tall-parts: a part taller than a page breaks and loses nothing, and one that fits moves whole"
