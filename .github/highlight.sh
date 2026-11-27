#!/bin/sh
# highlight.sh — code typst highlights in its own theme, whose colours are typst's and none of
# press's inks, is held to press's floors under any calibration: no lighter on white than the
# calibration's ink, and at least 4.5:1 on one of press's tints, the body floor tokens.typ gives,
# in a code block, a chip, a callout, a unit or a sheet's head and stripes; each colour darkened
# from typst's, its hue kept; and a theme of the document's own keeps its colours.
#
#   sh .github/highlight.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python.
# .github/highlight.typ sets lines of Typst and of Rust that between them draw every colour of
# typst's theme, alone on a page, as --input where= places them, under press's own calibration,
# an ink of 6 or a fill of 1.5. Each page is read as SVG, where each glyph's fill names its colour
# and where it stands, and each shape's its colour and its outline: the tints are the shapes paler
# than 3:1 on white. The colours typst's theme draws are read from the lines set with no press at
# all, and the page's own, its ink and its labels, from the same page set with no highlighting.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "highlight: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
py=${PRESS_PYTHON:-python3}

build() { # build <name> <input>…: highlight.typ, given the inputs, as $tmp/<name>.svg
    name=$1
    shift
    args=""
    for input in "$@"; do args="$args --input $input"; done
    # shellcheck disable=SC2086 # its words, an argument each
    typst compile --root . --font-path fonts --ignore-system-fonts $args .github/highlight.typ \
        "$tmp/$name.pdf"
    pdftocairo -svg "$tmp/$name.pdf" "$tmp/$name.svg"
}

# judge <page> <bare> <theirs> <ink> <where>: the page's glyphs against press's floors, and the
# colours it highlights in, those the same page set with no highlighting, bare, does not draw,
# against those typst's theme draws, theirs; then "ok", or what fails.
judge() {
    "$py" - "$@" <<'SVG'
import math, re, sys
page, bare, theirs, ink, where = sys.argv[1:]
ink = float(ink)
def lin(v): return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
def lum(c): return sum(w * lin(v) for w, v in zip((0.2126, 0.7152, 0.0722), c))
def on(c, ground): return (lum(ground) + 0.05) / (lum(c) + 0.05)
def hexed(c): return "".join("%02x" % round(v * 255) for v in c)
def oklch(c):
    r, g, b = (lin(v) for v in c)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return math.hypot(a, bb), math.degrees(math.atan2(bb, a)) % 360
def read(name):
    svg = open(name).read()
    body = svg[svg.find("</defs>"):]
    defs = re.finditer(r'<(?:symbol|g)[^>]*id="(glyph-[^"]*)"[^>]*>(.*?)</(?:symbol|g)>', svg, re.S)
    blank = {m.group(1) for m in defs if not re.search(r'd="[^"]*\S[^"]*"', m.group(2))}
    rgb = lambda s: tuple(float(v.strip().rstrip("%")) / 100 for v in s.split(","))
    shapes, glyphs = [], []
    for m in re.finditer(r'<path\b[^>]*\bfill="rgb\(([^)]*)\)"[^>]*\bd="([^"]*)"', body):
        xy = [float(v) for v in re.findall(r"-?[0-9.]+", m.group(2))]
        shapes.append((rgb(m.group(1)), min(xy[0::2]), min(xy[1::2]), max(xy[0::2]), max(xy[1::2])))
    for m in re.finditer(r'<g\b[^>]*\bfill="rgb\(([^)]*)\)"[^>]*>((?:\s*<use [^>]*>)+)', body):
        for u in re.finditer(r'<use xlink:href="#([^"]+)" x="([^"]+)" y="([^"]+)"', m.group(2)):
            if u.group(1) not in blank:
                glyphs.append((rgb(m.group(1)), float(u.group(2)), float(u.group(3))))
    tints = [s for s in shapes if on(s[0], (1, 1, 1)) < 3]
    return tints, glyphs
def colours(name): return {hexed(c): c for c, _, _ in read(name)[1]}
def no(why): print(why); sys.exit()

tints, glyphs = read(page)
for c, x, y in glyphs:
    under = [t for t in tints if t[1] <= x <= t[3] and t[2] <= y <= t[4]]
    if where == "white" and under:
        no("sets a glyph on a tint, #%s, where it should stand on white" % hexed(under[0][0]))
    if where != "white" and not under:
        no("sets #%s off its tint, at %s, %s" % (hexed(c), x, y))
    if on(c, (1, 1, 1)) < ink - 0.0005:
        no("sets text in #%s at %.2f:1 on white, under the calibration's ink, %.2f:1"
           % (hexed(c), on(c, (1, 1, 1)), ink))
    if under:
        t = min(under, key=lambda t: (t[3] - t[1]) * (t[4] - t[2]))[0]
        if on(c, t) < 4.5 - 0.0005:
            no("sets text in #%s at %.2f:1 on #%s, its tint, under the 4.5:1 floor"
               % (hexed(c), on(c, t), hexed(t)))
# typst's colours, its default black aside, and the page's highlighted ones, its own aside.
own = colours(bare)
drawn = {h: c for h, c in colours(page).items() if h not in own}
given = {h: c for h, c in colours(theirs).items() if h != "000000"}
if min(on(c, (1, 1, 1)) for c in given.values()) >= ink:
    no("typst's theme draws no colour under the calibration's ink, so the check proves nothing")
if len(drawn) != len(given):
    no("draws %d colours of typst's theme, where typst draws %d: %s, of %s"
       % (len(drawn), len(given), " ".join(sorted(drawn)), " ".join(sorted(given))))
for h, c in given.items():
    chroma, hue = oklch(c)
    def kept(d):
        dc, dh = oklch(d)
        turned = abs((dh - hue + 180) % 360 - 180)
        return on(d, (1, 1, 1)) >= on(c, (1, 1, 1)) - 0.0005 and (chroma < 0.02 or turned < 3)
    match = [k for k, d in drawn.items() if kept(d)]
    if not match:
        no("draws no colour that is typst's #%s, or it darkened, its hue kept" % h)
    del drawn[min(match, key=lambda k: abs((oklch(drawn[k])[1] - hue + 180) % 360 - 180))]
print("ok")
SVG
}

build theirs theme=plain
# Every colour typst's theme sets text in, over 20 languages, is one _floored holds: one it lacks
# is printed as typst gives it.
build every theme=plain where=every
missing=$("$py" - "$tmp/every.svg" lib/parts.typ <<'PY'
import re, sys
svg, parts = (open(n).read() for n in sys.argv[1:])
drawn = {"".join("%02x" % round(float(v.strip().rstrip("%")) * 2.55) for v in m.split(","))
         for m in re.findall(r'<g\b[^>]*\bfill="rgb\(([^)]*)\)"[^>]*>\s*<use ', svg)}
held = re.search(r'#let _theirs = \(([^)]*)\)', parts).group(1)
held = set(re.findall(r'"#([0-9a-f]{6})"', held))
print(" ".join("#" + c for c in sorted(drawn - held - {"000000"})))
PY
)
[ -z "$missing" ] \
    || fail "typst's theme sets text in $missing, which _theirs in lib/parts.typ does not hold"
checked=0
for cal in own ink-6 fill-1.5; do
    # The calibration's ink, as its contrast on white, as the template takes it.
    ink=$(typst query --root . --font-path fonts --ignore-system-fonts --input calibration="$cal" \
        .github/highlight.typ "<highlight-ink>" --field value --one 2>/dev/null)
    for where in white code chip callout unit head stripe; do
        build page where="$where" calibration="$cal"
        build bare where="$where" calibration="$cal" theme=none
        verdict=$(judge "$tmp/page.svg" "$tmp/bare.svg" "$tmp/theirs.svg" "$ink" "$where")
        [ "$verdict" = ok ] || fail "highlighted code, $where, given $cal, $verdict"
        checked=$((checked + 1))
    done
    echo "highlight: given $cal, highlighted code reads at press's floors, its hues kept"
done
for where in white code; do
    build grey where="$where" theme=grey
    "$py" - "$tmp/grey.svg" <<'PY' \
        || fail "a theme of the document's own, $where, does not keep its comments' #74747c"
import re, sys
svg = open(sys.argv[1]).read()
drawn = {"".join("%02x" % round(float(v.strip().rstrip("%")) * 2.55) for v in m.split(","))
         for m in re.findall(r'<g\b[^>]*\bfill="rgb\(([^)]*)\)"[^>]*>\s*<use ', svg)}
sys.exit(0 if "74747c" in drawn else 1)
PY
done
echo "highlight: a theme of the document's own keeps its colours"
echo "highlight: $checked pages: highlighted code reads at press's floors, under any calibration"
