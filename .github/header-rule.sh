#!/bin/sh
# header-rule.sh — header()'s rule clears the title's descenders.
#
#   sh .github/header-rule.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/header-rule.typ has
# a title with g, j, p, q and y. Its page is rendered at 288 dpi, and the rule is the first row
# dark across most of the width: the title's ink must stop at least 1pt above the rule's top, and
# none may show under the rule's foot. The rule once sat under the baseline, through the tails.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "header-rule: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/header-rule.typ "$tmp/probe.pdf"
pdftoppm -r 288 -gray -f 1 -l 1 -singlefile "$tmp/probe.pdf" "$tmp/page"
python3 -I - "$tmp/page.pgm" <<'PY' || exit 1
import sys

data = open(sys.argv[1], "rb").read()
magic, w, h, depth, px = data.split(maxsplit=4)
w, h = int(w), int(h)
dark = [sum(1 for x in range(w) if px[y * w + x] < 160) for y in range(h)]
rule = [y for y in range(h) if dark[y] > w * 0.6]
if not rule:
    sys.exit("header-rule: no rule found on the page")
top = foot = rule[0]
while dark[foot + 1] > w * 0.6:
    foot += 1
pt = 72 / 288
if dark[foot + 1] > 0:
    y = foot + 1
    while dark[y] > 0:
        y += 1
    sys.exit(f"header-rule: the title's ink runs {(y - foot - 1) * pt:.2f}pt under the rule's foot")
y = top - 1
while dark[y] == 0:
    y -= 1
clear = (top - 1 - y) * pt
if clear < 1:
    sys.exit(f"header-rule: the title's ink stops {clear:.2f}pt above the rule's top, under 1pt")
print(f"header-rule: the title's ink stops {clear:.2f}pt above the rule")
PY
echo "header-rule: header()'s rule clears the title's descenders"
