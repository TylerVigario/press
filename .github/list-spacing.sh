#!/bin/sh
# list-spacing.sh — a paragraph's lines are closer than a list's items, and its items closer
# than paragraphs, so each reads as one: an item that runs to a second line is not part of the
# next, a paragraph ends where its gap shows, and the paragraph after a list is not its last item.
#
#   sh .github/list-spacing.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. Under each template
# that sets its lists, .github/list-spacing.typ sets two paragraphs, a bulleted list, a numbered
# one and a checklist whose first item has a second line, and a paragraph after them. Each gap
# is read from the tops of the lines' first words, and must be wider than the one before it in
# that order: lines, then items, then paragraphs; a list's own gap from the text after it is a
# paragraph's. The same holds in the body of each part a document writes one in, callout(),
# panel(), unit(), item(), decision() and addendum(), each on a page of its own.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "list-spacing: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

. .github/word-box.sh
# top_of <word>: the top of the word's box, in points from the top of the page.
top_of() { word_box "$tmp/boxes.html" "$1" | awk '{ print $2 }'; }
for template in brief base recipe resume letter; do
    typst compile --root . --font-path fonts --ignore-system-fonts --input "template=$template" \
        .github/list-spacing.typ "$tmp/probe.pdf"
    pdftotext -bbox "$tmp/probe.pdf" "$tmp/boxes.html"
    p1=$(top_of Paraone) pl=$(top_of Paraline) p2=$(top_of Paratwo)
    b1=$(top_of Bulletline) b2=$(top_of Bullettwo) c2=$(top_of Checktwo) after=$(top_of Paraafter)
    [ -n "$p1" ] && [ -n "$pl" ] && [ -n "$p2" ] && [ -n "$after" ] || fail "$template: a paragraph is missing"
    awk -v line="$(awk -v a="$p1" -v b="$pl" 'BEGIN { print b - a }')" \
        -v item="$(awk -v a="$b1" -v b="$b2" 'BEGIN { print b - a }')" \
        -v para="$(awk -v a="$pl" -v b="$p2" 'BEGIN { print b - a }')" \
        -v tail="$(awk -v a="$c2" -v b="$after" 'BEGIN { print b - a }')" \
        'BEGIN { exit !(item > line + 0.5 && para > item + 0.5 && tail > para - 0.5) }' ||
        fail "$template: lines, items and paragraphs are not each further apart than the last"
    # A part's own pieces are no further apart than paragraphs: a unit's lead from its body, an
    # item's title from its body.
    for pair in Unitlead:Unitbody Itemtitle:Itembody; do
        a=$(top_of "${pair%%:*}") b=$(top_of "${pair#*:}")
        [ -n "$a" ] && [ -n "$b" ] || fail "$template: ${pair%%:*} is missing"
        awk -v gap="$(awk -v a="$a" -v b="$b" 'BEGIN { print b - a }')" \
            -v para="$(awk -v a="$pl" -v b="$p2" 'BEGIN { print b - a }')" 'BEGIN { exit !(gap < para) }' ||
            fail "$template: ${pair%%:*} is further from ${pair#*:} than paragraphs are apart"
    done
    # Inside each part whose body a document writes, its body spaces as the text around it does.
    for part in Callout Panel Unit Item Decision Addendum; do
        name=$(printf '%s' "$part" | tr '[:upper:]' '[:lower:]')
        one=$(top_of "${part}one") line=$(top_of "${part}line") two=$(top_of "${part}two")
        bline=$(top_of "${part}bline") btwo=$(top_of "${part}btwo") after=$(top_of "${part}after")
        [ -n "$one" ] && [ -n "$line" ] && [ -n "$two" ] && [ -n "$bline" ] && [ -n "$btwo" ] &&
            [ -n "$after" ] || fail "$template: ${name}()'s body is missing"
        awk -v line="$(awk -v a="$one" -v b="$line" 'BEGIN { print b - a }')" \
            -v item="$(awk -v a="$bline" -v b="$btwo" 'BEGIN { print b - a }')" \
            -v para="$(awk -v a="$line" -v b="$two" 'BEGIN { print b - a }')" \
            -v tail="$(awk -v a="$btwo" -v b="$after" 'BEGIN { print b - a }')" \
            'BEGIN { exit !(item > line + 0.5 && para > item + 0.5 && tail > para - 0.5) }' ||
            fail "$template: in ${name}()'s body, lines, items and paragraphs are not each further apart than the last"
    done
    for case in "Bullet:bulleted list" "Enum:numbered list" "Check:checklist"; do
        list=${case%%:*} name=${case#*:}
        one=$(top_of "${list}one") line=$(top_of "${list}line") two=$(top_of "${list}two")
        [ -n "$one" ] && [ -n "$line" ] && [ -n "$two" ] || fail "$template: the $name is missing"
        awk -v a="$one" -v b="$line" -v c="$two" 'BEGIN { exit !(c - b > b - a + 0.5) }' ||
            fail "$template: in a $name, the next item is $(awk -v b="$line" -v c="$two" \
                'BEGIN { printf "%.2f", c - b }')pt below an item's last line, no further than its lines"
    done
done
echo "list-spacing: lines, then items, then paragraphs, each further apart than the last, in the text and inside a part, and a part's own pieces closer than paragraphs, in every template"
