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
#
# .github/form-fill/probe.typ fills in the blank's first page with the measuring grid on, every
# 18pt. Its lines must run from the page's top-left corner, the heavy ones every fourth step,
# each crossing of two labelled beside it, and the audit must refuse the page for the grid and
# for nothing else: the grid's lines and labels are left out of its passes, as a scan is. A build
# without the audit's tools must still fail it, since finding the grid needs only typst.
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
# shellcheck disable=SC2086
typst compile $flags .github/form-fill/probe.typ "$tmp/probe.pdf"

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
pdftoppm -r 288 -gray "$tmp/probe.pdf" "$tmp/probe"
python3 -I - "$tmp/page-1.pgm" "$tmp/page-2.pgm" "$tmp/page-3.pgm" "$tmp/probe-1.pgm" <<'PY' \
    || fail "a form page is not as the document set it"
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

# ink(page, area): the box, in points, round the dark pixels inside an area, in points; with
# faint, any pixel not white, as the grid's blue is.
def ink(page, area, faint=False):
    width, px = page
    x0, y0, x1, y1 = (int(v * 4) for v in area)
    xs, ys = [], []
    for y in range(y0, y1):
        for x in range(x0, x1):
            if px[y * width + x] < (230 if faint else 128):
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return min(xs) / 4, min(ys) / 4, (max(xs) + 1) / 4, (max(ys) + 1) / 4

own, letter, a4, probe = (load(p) for p in sys.argv[1:5])
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

# The grid, every 18pt: each line where its step puts it, read between the crossings and clear of
# the labels, where the blank has no ink of its own.
for what, area, at, axis in (("the heavy line at x 72pt", (70, 310, 74, 320), 72, 0),
                             ("the light line at x 90pt", (88, 310, 92, 320), 90, 0),
                             ("the heavy line at y 360pt", (330, 358, 340, 362), 360, 1)):
    line = ink(probe, area, faint=True)
    if line is None or abs((line[axis] + line[axis + 2]) / 2 - at) > 0.5:
        bad.append(f"the measuring grid drew {what} at {line}")

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

pdftotext -bbox "$tmp/probe.pdf" - \
    | awk -F '"' '/>216,</ && $2 >= 216 && $2 <= 220 && $4 >= 216 && $4 <= 220 { hit = 1 } END { exit !hit }' \
    || fail "the grid's label for 216, 216 is not beside its crossing"
echo "form-fill: the measuring grid runs from the page's corner, every step, its crossings labelled"

# shellcheck disable=SC2086
! sh tools/check.sh .github/form-fill/probe.typ "$tmp/probe-audit.pdf" . $flags > "$tmp/out" 2>&1 \
    || fail "a form with the measuring grid on audited clean"
grep -qF "has the measuring grid on" "$tmp/out" || { cat "$tmp/out" >&2; fail "the audit refused the grid, but not for it"; }
[ "$(grep -c '^press:' "$tmp/out")" -eq 1 ] || { cat "$tmp/out" >&2; fail "the grid's lines and labels were audited as the document's"; }
echo "form-fill: the audit refuses a form with the measuring grid on, for that alone"

# The grid needs only typst to be found, so a build without the audit's tools still fails for it.
# shellcheck disable=SC2086
! PRESS_PDFTOTEXT=/nonexistent/pdftotext sh tools/stamp.sh .github/form-fill/probe.typ "$tmp/probe-build.pdf" $flags \
    > "$tmp/out" 2>&1 || fail "a build without poppler passed a form with the measuring grid on"
grep -qF "has the measuring grid on" "$tmp/out" || { cat "$tmp/out" >&2; fail "a build without poppler failed, but not for the grid"; }
echo "form-fill: a build without the audit's tools still fails a form with the measuring grid on"
