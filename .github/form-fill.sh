#!/bin/sh
# form-fill.sh — a form page is its blank's own, and each answer lands where the document put it.
#
#   sh .github/form-fill.sh
#
# Run by CI's audit job and the oldest-toolchain job, which have poppler. .github/form-fill.typ
# fills in a stand-in blank, a letter page and an A4 page, under brief, between two pages of its
# own. Each form page must be its blank's size, without brief's footer, and each answer's ink must
# be where the document put it, read off the page rendered at four pixels to the point: a box set
# at() a point starts there, a tick() is centred on its point, and an answer given a width wraps
# inside it. The filled document must audit clean, the blank under its answers left out.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "form-fill: $*" >&2; exit 1; }
tmp=$(mktemp -d)
blank=.github/form-fill/blank.pdf
trap 'rm -rf "$tmp"; rm -f "$blank"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

flags="--root . --font-path fonts --ignore-system-fonts"
typst compile --root . --ignore-system-fonts .github/form-fill/blank.typ "$blank"
# shellcheck disable=SC2086
typst compile $flags .github/form-fill.typ "$tmp/filled.pdf"

# size <page>: the page's size in points, as pdfinfo prints it.
size() { pdfinfo -f "$1" -l "$1" "$tmp/filled.pdf" | sed -n "s/^Page *$1 size: *\([0-9.]* x [0-9.]*\) pts.*/\1/p"; }
[ "$(size 2)" = "612 x 792" ] || fail "the letter form page is $(size 2) points, not its blank's 612 x 792"
[ "$(size 3)" = "595.276 x 841.89" ] || fail "the A4 form page is $(size 3) points, not its blank's 595.276 x 841.89"
echo "form-fill: each form page is its blank's size"

# The document's own pages carry its header, so its absence from the form pages means something.
# With no margin a header still prints along the top edge, and pdftotext reads what shows.
pdftotext -f 1 -l 1 "$tmp/filled.pdf" - | grep -qF "A header of" || fail "the document's own page has no header to compare"
! pdftotext -f 2 -l 3 "$tmp/filled.pdf" - | grep -qF "A header of" || fail "a form page carries the document's header"

pdftoppm -r 288 -gray -f 1 -l 3 "$tmp/filled.pdf" "$tmp/page"
python3 -I - "$tmp/page-1.pgm" "$tmp/page-2.pgm" "$tmp/page-3.pgm" <<'PY' || fail "a form page is not as the document set it"
import sys

def load(path):
    data = open(path, "rb").read()
    fields, i = [], 0
    while len(fields) < 4:
        while data[i:i + 1].isspace():
            i += 1
        j = i
        while not data[j:j + 1].isspace():
            j += 1
        fields.append(data[i:j])
        i = j
    width, height = int(fields[1]), int(fields[2])
    return width, data[i + 1:]

# ink(page, area): the box, in points, round the dark pixels inside an area, in points.
def ink(page, area):
    width, px = page
    x0, y0, x1, y1 = (int(v * 4) for v in area)
    xs, ys = [], []
    for y in range(y0, y1):
        for x in range(x0, x1):
            if px[y * width + x] < 128:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return min(xs) / 4, min(ys) / 4, (max(xs) + 1) / 4, (max(ys) + 1) / 4

own, letter, a4 = (load(p) for p in sys.argv[1:4])
bad = []

# The document's background and foreground, on its own page and on neither form page.
for name, area in (("background", (38, 298, 52, 312)), ("foreground", (38, 328, 52, 342))):
    if ink(own, area) is None:
        bad.append(f"the document's own page has no {name} to compare")
    for which, page in (("letter", letter), ("A4", a4)):
        if ink(page, area) is not None:
            bad.append(f"the {which} form page carries the document's {name}")

def near(a, b, within):
    return all(abs(p - q) <= within for p, q in zip(a, b))

box = ink(letter, (90, 190, 140, 220))
if box is None or not near(box, (100, 200, 120, 210), 0.25):
    bad.append(f"a 20pt by 10pt box at(100pt, 200pt) inked {box}")
mark = ink(letter, (285, 385, 315, 415))
if mark is None or not near(((mark[0] + mark[2]) / 2, (mark[1] + mark[3]) / 2), (300, 400), 0.5):
    bad.append(f"tick(300pt, 400pt) inked {mark}, not centred on its point")
wrap = ink(letter, (60, 480, 250, 640))
if wrap is None or wrap[0] < 72 or wrap[2] > 132 or wrap[3] - wrap[1] < 30:
    bad.append(f"an answer 60pt wide at(72pt, 500pt) inked {wrap}, not wrapped inside 72pt to 132pt")
box = ink(a4, (290, 290, 340, 315))
if box is None or not near(box, (300, 300, 330, 305), 0.25):
    bad.append(f"a 30pt by 5pt box at(300pt, 300pt) on the A4 page inked {box}")

for b in bad:
    print("form-fill: " + b, file=sys.stderr)
sys.exit(1 if bad else 0)
PY
echo "form-fill: a form page carries nothing of the document's own: no header, background or foreground"
echo "form-fill: each answer lands where at() and tick() put it, and a wide one wraps inside its width"

# shellcheck disable=SC2086
sh tools/check.sh .github/form-fill.typ "$tmp/audit.pdf" . $flags > "$tmp/out" 2>&1 \
    || { cat "$tmp/out" >&2; fail "the filled form failed its audit"; }
echo "form-fill: the filled form audits clean, its blank left out"
