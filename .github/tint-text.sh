#!/bin/sh
# tint-text.sh — a part that sets text on one of press's tints, a chip, a callout, a unit, a code
# block or a sheet, sets it at least 4.5:1 on the tint, the body floor tokens.typ gives, under any
# calibration, one whose fill darkens the tint among them: its label, and the document's own text
# in any of press's inks; and a tone's shape there takes its label's colour.
#
#   sh .github/tint-text.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python.
# .github/tint-text.typ sets the part alone on a page, under press's own calibration or one whose
# fill darkens every tint, and with --input words=true the document's own text in it, in each of
# press's inks. Each page is read as SVG, where each glyph's fill names its colour and where it
# stands, and each shape's its colour and its outline: the tints are the shapes paler than 3:1 on
# white, and every glyph must stand on one and be at least 4.5:1 on it; and on a page with the label
# alone, the label's colour must fill a shape too, the tone's.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "tint-text: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
py=${PRESS_PYTHON:-python3}

# read <svg>: the page's glyph colours, each as "glyph", its shapes' as "shape", with each
# colour's contrast on white, then "least": the glyph least in contrast on the tint it stands on,
# that contrast and the tint, or "least none" where no glyph stands on a tint, or "off" and a glyph
# that stands on none.
read_page() {
    "$py" - "$1" <<'SVG'
import re, sys
svg = open(sys.argv[1]).read()
page = svg[svg.find("</defs>"):]
glyphs = re.finditer(r'<(?:symbol|g)[^>]*id="(glyph-[^"]*)"[^>]*>(.*?)</(?:symbol|g)>', svg, re.S)
blank = {m.group(1) for m in glyphs if not re.search(r'd="[^"]*\S[^"]*"', m.group(2))}
def lum(c):
    c = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
hexed = lambda c: "".join("%02x" % round(v * 255) for v in c)
on_white = lambda c: 1.05 / (lum(c) + 0.05)
rgb = lambda s: tuple(float(v.strip().rstrip("%")) / 100 for v in s.split(","))
shapes, placed = [], []
for m in re.finditer(r'<path\b[^>]*\bfill="rgb\(([^)]*)\)"[^>]*\bd="([^"]*)"', page):
    xy = [float(v) for v in re.findall(r"-?[0-9.]+", m.group(2))]
    shapes.append((rgb(m.group(1)), min(xy[0::2]), min(xy[1::2]), max(xy[0::2]), max(xy[1::2])))
for m in re.finditer(r'<g\b[^>]*\bfill="rgb\(([^)]*)\)"[^>]*>((?:\s*<use [^>]*>)+)', page):
    for u in re.finditer(r'<use xlink:href="#([^"]+)" x="([^"]+)" y="([^"]+)"', m.group(2)):
        if u.group(1) not in blank:
            placed.append((rgb(m.group(1)), float(u.group(2)), float(u.group(3))))
for kind, colours in (("glyph", {c for c, _, _ in placed}), ("shape", {s[0] for s in shapes})):
    for c in sorted(colours, key=lum):
        print(kind, hexed(c), "%.4f" % on_white(c))
tints = [s for s in shapes if on_white(s[0]) < 3]
least = None
for c, x, y in placed:
    under = [t for t in tints if t[1] <= x <= t[3] and t[2] <= y <= t[4]]
    if not under:
        print("off", hexed(c), x, y)
        sys.exit()
    # The tint it stands on: the smallest that holds it, drawn over any larger.
    t = min(under, key=lambda t: (t[3] - t[1]) * (t[4] - t[2]))[0]
    r = (lum(t) + 0.05) / (lum(c) + 0.05)
    if least is None or r < least[1]:
        least = (c, r, t)
if least is None:
    print("least none")
else:
    print("least", hexed(least[0]), "%.2f" % least[1], hexed(least[2]))
SVG
}

checked=0
for cal in own fill-1.3 fill-1.5 fill-1.5-ink-6; do
    for part in chip callout unit code sheet; do
        case $part in chip | callout | unit) tones="note ok warn bad" ;; *) tones=ok ;; esac
        for tone in $tones; do
            for words in true false; do
                case $part:$words in code:false | sheet:false) continue ;; esac
                typst compile --root . --font-path fonts --ignore-system-fonts --input part="$part" \
                    --input tone="$tone" --input calibration="$cal" --input words="$words" \
                    .github/tint-text.typ "$tmp/page.pdf"
                pdftocairo -svg "$tmp/page.pdf" "$tmp/page.svg"
                read_page "$tmp/page.svg" > "$tmp/read"
                ! grep -q '^off ' "$tmp/read" || { cat "$tmp/read" >&2
                    fail "a $part in $tone, given $cal, sets text off its tint: $(grep '^off ' "$tmp/read")"; }
                # shellcheck disable=SC2046 # its words, one an argument
                set -- $(grep '^least ' "$tmp/read")
                [ "$2" != none ] || fail "a $part in $tone, given $cal, draws no tint or no text"
                awk -v r="$3" 'BEGIN { exit !(r >= 4.5) }' || { cat "$tmp/read" >&2
                    fail "a $part in $tone, given $cal, words $words, sets text in #$2 at $3:1 on #$4, its tint, under the 4.5:1 floor"; }
                if [ "$words" = false ]; then
                    # The label: the palest glyph, the tone's colour, which its shape takes too.
                    label=$(grep '^glyph ' "$tmp/read" | sort -k3,3g | head -n 1 | cut -d' ' -f2)
                    grep -q "^shape $label " "$tmp/read" || { cat "$tmp/read" >&2
                        fail "a $part in $tone, given $cal, sets its label in #$label, which no shape on its tint takes"; }
                fi
                checked=$((checked + 1))
            done
        done
        echo "tint-text: given $cal, a $part sets its text at least 4.5:1 on its tint"
    done
done
echo "tint-text: $checked pages: a part sets its text at least 4.5:1 on its tint, under any calibration"
