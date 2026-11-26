#!/bin/sh
# tones.sh — a chip and a callout set each tone's label at least 4.5:1 on the tone's tint, the
# body floor tokens.typ gives, under press's own calibration.
#
#   sh .github/tones.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python.
# .github/tones.typ sets a boxed chip, or a callout with a label, in one tone, alone on a page.
# Each page is read as SVG, where every fill and stroke names its colour: the page must draw the
# tone's colour and its tint as tokens.typ writes them, and every colour it draws, the label's
# among them, must be at least 4.5:1 on the tint, the palest.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "tones: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
py=${PRESS_PYTHON:-python3}

# Each tone, its colour and its tint, as six hex digits: parts.typ's tones, by tokens.typ's colours.
"$py" - lib/parts.typ lib/tokens.typ > "$tmp/tones" <<'PY'
import re, sys
parts, tokens = (open(f).read() for f in sys.argv[1:])
table = re.search(r'#let tones = \((.*?)\n\)', parts, re.S).group(1)
hexes = dict(re.findall(r'#let ([a-z-]+) = rgb\("#(\w{6})"\)', tokens))
for tone, colour, tint in re.findall(r'([a-z]+): \(([a-z-]+), ([a-z-]+)\)', table):
    print(tone, hexes[colour].lower(), hexes[tint].lower())
PY
[ "$(wc -l < "$tmp/tones")" -ge 4 ] || fail "found $(wc -l < "$tmp/tones") tones in parts.typ, where it has note, ok, warn and bad"

# colours <svg>: each colour the page draws, as six hex digits: every fill and stroke, but not a
# glyph with no outline, a space, which prints nothing whatever its colour.
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
# against <tint> <colour>...: each colour's contrast on the tint, WCAG's, to two places.
against() {
    "$py" - "$@" <<'PY'
import sys
def lum(h):
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
tint = lum(sys.argv[1])
for h in sys.argv[2:]:
    l = lum(h)
    print(h, "%.2f" % ((max(l, tint) + 0.05) / (min(l, tint) + 0.05)))
PY
}

while read -r tone colour tint; do
    for part in chip callout; do
        typst compile --root . --font-path fonts --ignore-system-fonts --input part="$part" \
            --input tone="$tone" .github/tones.typ "$tmp/page.pdf"
        pdftocairo -svg "$tmp/page.pdf" "$tmp/page.svg"
        colours "$tmp/page.svg" > "$tmp/drawn"
        grep -qx "$tint" "$tmp/drawn" || fail "a $part in $tone draws no #$tint, its tint, but $(paste -sd' ' "$tmp/drawn")"
        grep -qx "$colour" "$tmp/drawn" || fail "a $part in $tone draws no #$colour, its colour, but $(paste -sd' ' "$tmp/drawn")"
        # shellcheck disable=SC2046 # one colour a word
        palest=$(against ffffff $(cat "$tmp/drawn") | sort -k2,2g | head -n 1 | cut -d' ' -f1)
        [ "$palest" = "$tint" ] || fail "a $part in $tone draws #$palest, paler than #$tint, its tint"
        # shellcheck disable=SC2046 # one colour a word
        against "$tint" $(grep -vx "$tint" "$tmp/drawn") > "$tmp/ratios"
        while read -r hex ratio; do
            awk -v r="$ratio" 'BEGIN { exit !(r >= 4.5) }' \
                || fail "a $part in $tone draws #$hex at $ratio:1 on #$tint, its tint, under the 4.5:1 floor"
        done < "$tmp/ratios"
        echo "tones: a $part in $tone draws its label #$colour at $(grep "^$colour " "$tmp/ratios" | cut -d' ' -f2):1 on #$tint"
    done
done < "$tmp/tones"
echo "tones: under press's own calibration, a chip and a callout set each tone's label at least 4.5:1 on its tint"
