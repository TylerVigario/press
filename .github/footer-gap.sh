#!/bin/sh
# footer-gap.sh — footer() keeps its title and status apart from its stamp and page, by the gap
# header() keeps between its title and its meta, however long the title.
#
#   sh .github/footer-gap.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/footer-gap.typ
# sets the footer on pages half a point apart in width, so the title's end comes to every
# distance from the stamp, on one line and wrapped. On every page, "updated" must be a word of its
# own, and each word on its line before it must end at least that gap short of it.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "footer-gap: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

gap=$(sed -n 's/^#let _sides-gap = \([0-9.]*\)pt$/\1/p' lib/parts.typ)
[ -n "$gap" ] || fail "lib/parts.typ sets no _sides-gap in points"
typst compile --root . --font-path fonts --ignore-system-fonts \
    --input "press-updated=2023-11-14 22:13:20 UTC" .github/footer-gap.typ "$tmp/footer.pdf"
pdftotext -bbox "$tmp/footer.pdf" "$tmp/footer.html"

# Each page: its number, then "one" or "wrapped", and the space before "updated" in points; or
# its number and "none" where "updated" is not a word of its own.
awk '
    function attr(k) {
        match($0, k "=\"[0-9.]+\"")
        return substr($0, RSTART + length(k) + 2, RLENGTH - length(k) - 3) + 0
    }
    function done() {
        if (!page) return
        if (ux == "") { print page, "none"; return }
        end = -1; below = 0
        for (i = 1; i <= n; i++) {
            if (y0[i] > uy + 1) below = 1
            else if (y0[i] > uy - 1 && x1[i] <= ux) { if (x1[i] > end) end = x1[i] }
        }
        printf "%d %s %.2f\n", page, below ? "wrapped" : "one", end < 0 ? 999 : ux - end
    }
    /<page / { done(); page++; n = 0; ux = ""; uy = "" }
    /<word / {
        w = $0; sub(/^.*">/, "", w); sub(/<\/word>.*$/, "", w)
        if (w == "updated") { ux = attr("xMin"); uy = attr("yMin") }
        else { n++; x1[n] = attr("xMax"); y0[n] = attr("yMin") }
    }
    END { done() }
' "$tmp/footer.html" > "$tmp/pages"

[ "$(wc -l < "$tmp/pages" | tr -d ' ')" -eq 33 ] || fail "the footer is not on 33 pages"
p=$(awk '$2 == "none" { print $1; exit }' "$tmp/pages")
[ -z "$p" ] || fail "on page $p, \"updated\" is not a word of its own: the title runs into it"
near=$(awk -v g="$gap" '$3 < g - 0.1 { print; exit }' "$tmp/pages")
if [ -n "$near" ]; then
    set -- $near
    case $2 in one) how="on one line" ;; *) how="wrapped" ;; esac
    fail "on page $1, the title, $how, ends ${3}pt short of the stamp, under ${gap}pt"
fi
grep -q ' one ' "$tmp/pages" || fail "the title wraps on every page: none is on one line"
grep -q ' wrapped ' "$tmp/pages" || fail "the title wraps on no page: none is too long for one"
min=$(sort -k3,3n "$tmp/pages" | head -n 1 | cut -d ' ' -f 3)
echo "footer-gap: footer() keeps its title ${min}pt or more from its stamp, however long the title"
