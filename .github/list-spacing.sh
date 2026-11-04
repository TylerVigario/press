#!/bin/sh
# list-spacing.sh — a list's items are further apart than the lines within one, so an item that
# runs to a second line reads as one item, not as part of the next.
#
#   sh .github/list-spacing.sh
#
# Run by CI's audit job and the oldest-toolchain job, which have poppler. Under each template
# that sets its lists, .github/list-spacing.typ sets a bulleted list, a numbered one and a
# checklist whose first item has a second line; the gap from that line to the next item must be
# wider than the gap between the item's own two lines.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "list-spacing: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# top_of <word>: the top of the word's box, in points from the top of the page.
top_of() {
    awk -v w="$1" 'index($0, ">" w "<") {
        match($0, /yMin="[0-9.]+"/); print substr($0, RSTART + 6, RLENGTH - 7); exit }' "$tmp/boxes.html"
}
for template in brief base recipe resume; do
    typst compile --root . --font-path fonts --ignore-system-fonts --input "template=$template" \
        .github/list-spacing.typ "$tmp/probe.pdf"
    pdftotext -bbox "$tmp/probe.pdf" "$tmp/boxes.html"
    for case in "Bullet:bulleted list" "Enum:numbered list" "Check:checklist"; do
        list=${case%%:*} name=${case#*:}
        one=$(top_of "${list}one") line=$(top_of "${list}line") two=$(top_of "${list}two")
        [ -n "$one" ] && [ -n "$line" ] && [ -n "$two" ] || fail "$template: the $name is missing"
        awk -v a="$one" -v b="$line" -v c="$two" 'BEGIN { exit !(c - b > b - a + 0.5) }' ||
            fail "$template: in a $name, the next item is $(awk -v b="$line" -v c="$two" \
                'BEGIN { printf "%.2f", c - b }')pt below an item's last line, no further than its lines"
    done
done
echo "list-spacing: a list's items are further apart than the lines within one, in every template"
