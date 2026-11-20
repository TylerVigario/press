#!/bin/sh
# continued-gap.sh — continued() keeps a letter's writer, its date and its page apart, by the gap
# header() keeps between its title and its meta, however long the writer's name.
#
#   sh .github/continued-gap.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/continued-gap.typ
# sets a letter whose pages after the first are half a point apart in width, so the name's end
# comes to every distance from the date, on one line and wrapped. On every one of them, the
# date's first word must be a word of its own, every word of the name beside it must end at
# least that gap short of it, and the date must end at least that gap short of the page.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "continued-gap: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

gap=$(sed -n 's/^#let _sides-gap = \([0-9.]*\)pt$/\1/p' lib/parts.typ)
[ -n "$gap" ] || fail "lib/parts.typ sets no _sides-gap in points"
typst compile --root . --font-path fonts --ignore-system-fonts .github/continued-gap.typ \
    "$tmp/letter.pdf"
pdftotext -bbox "$tmp/letter.pdf" "$tmp/letter.html"

# Each page after the first: its number, "one" or "wrapped", the space after the name and the
# space before the page, in points; or its number and "none" where the date's "18" is not a
# word of its own.
awk '
    function attr(k) {
        match($0, k "=\"[0-9.]+\"")
        return substr($0, RSTART + length(k) + 2, RLENGTH - length(k) - 3) + 0
    }
    function done() {
        if (page < 2) return
        if (dx == "") { print page, "none"; return }
        end = -1; wrapped = 0
        for (i = 1; i <= n; i++) {
            if (w[i] ~ /^Writer/) {
                if (y0[i] < dy - 1) wrapped = 1
                else if (y0[i] < dy + 1 && x1[i] <= dx && x1[i] > end) end = x1[i]
            }
        }
        printf "%d %s %.2f %.2f\n", page, wrapped ? "wrapped" : "one", end < 0 ? 999 : dx - end,
            px - yx
    }
    /<page / { done(); page++; n = 0; dx = ""; dy = ""; yx = ""; px = "" }
    /<word / {
        t = $0; sub(/^.*">/, "", t); sub(/<\/word>.*$/, "", t)
        if (t == "18") { dx = attr("xMin"); dy = attr("yMin") }
        else if (t == "2026" && dy != "" && attr("yMin") < dy + 1) yx = attr("xMax")
        else if (t == "Page" && dy != "" && attr("yMin") < dy + 1) px = attr("xMin")
        else { n++; w[n] = t; x1[n] = attr("xMax"); y0[n] = attr("yMin") }
    }
    END { done() }
' "$tmp/letter.html" > "$tmp/pages"

[ "$(wc -l < "$tmp/pages" | tr -d ' ')" -eq 57 ] || fail "continued() is not on 57 pages"
p=$(awk '$2 == "none" { print $1; exit }' "$tmp/pages")
[ -z "$p" ] || fail "on page $p, the date's \"18\" is not a word of its own: the name runs into it"
near=$(awk -v g="$gap" '$3 < g - 0.1 { print; exit }' "$tmp/pages")
if [ -n "$near" ]; then
    set -- $near
    case $2 in one) how="on one line" ;; *) how="wrapped" ;; esac
    fail "on page $1, the name, $how, ends ${3}pt short of the date, under ${gap}pt"
fi
near=$(awk -v g="$gap" '$4 < g - 0.1 { print; exit }' "$tmp/pages")
[ -z "$near" ] \
    || fail "on page ${near%% *}, the date ends ${near##* }pt short of the page, under ${gap}pt"
grep -q ' one ' "$tmp/pages" || fail "the name wraps on every page: none is on one line"
grep -q ' wrapped ' "$tmp/pages" || fail "the name wraps on no page: none is too long for one"
echo "continued-gap: continued() keeps a letter's writer, date and page ${gap}pt or more apart"
