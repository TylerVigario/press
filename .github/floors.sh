#!/bin/sh
# floors.sh — a template set for a calibration draws press's inks, tints and rules no fainter
# than its floors: given floors above press's own, no ink or tint of press's that they darken
# prints as it was, a document's own text in one of press's inks included, and no rule prints
# thinner than its floor; given press's own calibration, each template lays out as given none.
#
#   sh .github/floors.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python.
# .github/floors.typ sets every part of press's that draws in its inks, tints or rules, in the
# template --input template= names, given the calibration --input calibration= names: none,
# press's own (own), or floors far above it (floors), the lightest ink 9:1, the palest fill 1.3:1
# and every rule 1.5pt; compiling it asserts what calibrated() hands back. Which of press's colours
# those floors darken is worked out here again, from tokens.typ, apart from press's own reckoning.
# Each page is read as SVG, where every fill and stroke names its colour, and every line drawn as
# a stroke its width.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "floors: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

py=${PRESS_PYTHON:-python3}
build() {
    typst compile --root . --font-path fonts --ignore-system-fonts --input template="$1" \
        --input calibration="$2" .github/floors.typ "$tmp/$1-$2.pdf"
    pdftocairo -svg "$tmp/$1-$2.pdf" "$tmp/$1-$2.svg"
}
look() { pdftoppm -r 40 -gray "$1" | sha256sum; }

# The colours of press's own, as tokens.typ writes them, that floors of 9:1 for an ink and 1.3:1
# for a tint darken: WCAG's contrast on white, computed here.
"$py" - lib/tokens.typ > "$tmp/darkened" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
def contrast(h):
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 1.05 / (0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2] + 0.05)
tokens = dict(re.findall(r'#let ([a-z-]+) = rgb\("#(\w{6})"\)', src))
inks = ("ink", "ink-soft", "ink-faint", "slate", "steel", "ok", "warn", "bad")
tints = ("paper-tint", "slate-tint", "ok-tint", "warn-tint", "bad-tint")
for name in inks + tints:
    floor = 9 if name in inks else 1.3
    if contrast(tokens[name]) < floor:
        print(tokens[name].lower(), name)
PY
[ -s "$tmp/darkened" ] || fail "floors of 9:1 and 1.3:1 darken none of press's colours, so the check proves nothing"

# colours <svg>: each colour the page draws ink in, as six hex digits: every fill and stroke, but
# not a glyph with no outline, a space, which prints nothing whatever its colour.
colours() {
    "$py" - "$1" <<'SVG'
import re, sys
svg = open(sys.argv[1]).read()
glyphs = re.finditer(r'<(?:symbol|g)[^>]*id="(glyph-[^"]*)"[^>]*>(.*?)</(?:symbol|g)>', svg, re.S)
blank = {m.group(1) for m in glyphs if not re.search(r'd="[^"]*\S[^"]*"', m.group(2))}
drawn = re.finditer(
    r'(fill|stroke)="rgb\(([^)]*)\)"[^>]*>(\s*<use xlink:href="#([^"]+)"[^>]*/>\s*</g>)?', svg)
seen = set()
for m in drawn:
    if m.group(4) in blank:
        continue
    seen.add("".join("%02x" % int(float(v.strip().rstrip("%")) * 2.55 + 0.5)
                     for v in m.group(2).split(",")))
print("\n".join(sorted(seen)))
SVG
}
# found <svg>: those of the darkened colours the page draws, by name.
found() { colours "$1" | while read -r hex; do grep "^$hex " "$tmp/darkened" || true; done; }
# thinnest <svg>: the narrowest line the page draws as a stroke, in points.
thinnest() {
    grep -o 'stroke-width="[^"]*"' "$1" | sed 's/.*="//; s/"//' | sort -g | head -1
}

for t in base brief letter recipe resume; do
    for c in none own floors; do build "$t" "$c"; done
    [ -n "$(found "$tmp/$t-none.svg")" ] \
        || fail "$t, given no calibration, draws none of the colours the floors darken, so their absence proves nothing"
    left=$(found "$tmp/$t-floors.svg" | awk '{ print $2 }' | tr '\n' ' ')
    [ -z "$left" ] || fail "$t, given floors of 9:1 and 1.3:1, still draws $left as it was"
    w=$(thinnest "$tmp/$t-none.svg")
    "$py" -c "import sys; sys.exit(0 if float(sys.argv[1]) < 1.5 else 1)" "$w" \
        || fail "$t, given no calibration, draws no line thinner than 1.5pt, so the floor proves nothing"
    w=$(thinnest "$tmp/$t-floors.svg")
    "$py" -c "import sys; sys.exit(0 if float(sys.argv[1]) >= 1.5 - 1e-6 else 1)" "$w" \
        || fail "$t, given rules of 1.5pt, draws a line ${w}pt wide"
    [ "$(look "$tmp/$t-own.pdf")" = "$(look "$tmp/$t-none.pdf")" ] \
        || fail "$t, given press's own calibration, lays out otherwise than given none"
done
echo "floors: a calibration's floors darken press's inks and tints, and widen its rules"
