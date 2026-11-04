#!/bin/sh
# head-gaps.sh — a header, a == heading and a résumé entry keep their own gaps inside them,
# whatever paragraph spacing the document sets.
#
#   sh .github/head-gaps.sh
#
# Run by CI's audit job and the oldest-toolchain job. typst takes a block's spacing from the
# paragraph spacing, and a heading's inner blocks take the heading's, so a part that left its
# inside to them would grow with every document's spacing. .github/head-gaps.typ measures each
# under a tight spacing and a loose one, and each must measure the same under both.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "head-gaps: $*" >&2; exit 1; }

# heights <spacing>: the three heights, on one line.
heights() {
    for part in header heading entry; do
        typst query --root . --font-path fonts --ignore-system-fonts --input "spacing=$1" \
            .github/head-gaps.typ "<$part>" --field value 2>/dev/null | tr -d '[]" \n'
        printf ' '
    done
}
tight=$(heights 0.55em) loose=$(heights 2em)
[ -n "$(echo "$tight" | tr -d ' ')" ] || fail "the probe measured nothing"
[ "$tight" = "$loose" ] ||
    fail "header, == heading and entry measure $tight under 0.55em spacing and $loose under 2em"
echo "head-gaps: a header, a == heading and a résumé entry keep their own gaps"
