#!/usr/bin/env python3
"""Report lines of text printed on top of other lines, per page.

Exists because a document can collide with itself, pass every other check, and
reach paper. Nothing typst emits is wrong — the document is valid and it simply
renders on top of itself — so there is no warning to read and no font to blame.
It was found in practice by a person looking at a rendered page, more than once,
which is the failure mode `check` exists to remove.

Reads every glyph as drawn from poppler's `pdftocairo -svg`, and the words they
spell from `pdftotext -bbox-layout`, to name a finding, so it needs poppler — the
same dependency `check` already asserts — plus a Python to run this file.

WHY NOT THE RASTER, given the printable-area check already renders each page
----------------------------------------------------------------------------
Because a rendered page has thrown the answer away. "Two lines drawn on each
other" and "one line drawn once" are the same pixels; nothing in the image says
what was drawn on top of what. Tested anyway rather than assumed — merged-band
detection over a five-document corpus at six thresholds from 0.001 to 0.05 scored
ZERO on the known defect at every threshold while false-positiving on a clean
document at the low end. There is no setting that separates them.

The SVG works because it keeps what the raster discards: each glyph is drawn
apart, at its own place, so which line a glyph is on is known. That is also why
the printable-area check stays raster while this one cannot: "is there ink near
the paper edge" needs no layering at all and must see panels and rules as well
as glyphs, whereas layering is the entire question here.

WHY GLYPH OUTLINES RATHER THAN POPPLER'S WORD BOXES
---------------------------------------------------
This pass read pdftotext's word boxes until text turned to a slant. A word's box
stands upright around it, so a slanted word's box holds far more than its glyphs,
and the boxes of two slanted lines meet where no glyph does: a RECEIVED stamp of
two lines at -30° read as 2.26pt of text on text, and a two-line note at 10° as
5.03pt, past the smallest genuine collision then measured, with nothing on the
page touching. poppler also cuts slanted text into pieces of words and joins
pieces of two lines into one, "IVE 26", so its lines say nothing of which line a
glyph is on. pdftocairo draws each glyph from its outline, slanted as it prints,
so this pass measures the outlines themselves.

WHY BASELINES
-------------
A line is the glyphs on one baseline. The first attempt at lines of its own
grouped words by their vertical MIDPOINT, and on a known-good four-page document
produced 23 false positives, worst at 7.90pt, every one prose beside an inline
`raw` span: mono at a smaller size has another vertical centre, so one line read
as two. A baseline is the same for every face in a line, which is how typst sets
it. Each glyph's origin lies on its baseline, so glyphs whose origins share one
are one line, whatever their face or size. A slanted line's baseline slants, the
way its glyphs advance, read from the steps between them; cairo gives a font at a
slant a glyph set of its own, so each set advances one way.

A footnote marker sits on a raised baseline of its own, so it is a line of its
own, beside its word and touching no glyph of it, as a marker should.
"""
import math, os, re, subprocess, sys, tempfile, pathlib

# Two glyphs of different lines must overlap by more than this to be reported:
# their outlines' hulls, by how far one must move to clear the other. Not tuned
# to taste. A glyph's hull is its outline's, with each curve read at points along
# it, so where it falls short of the curve, by a hair, it errs toward passing.
# Measured across 159 clean documents, no glyph of one line overlapped a glyph of
# another at all, 0.00pt; the known collisions, upright and slanted, overlap by
# 3.79pt and more.
EPSILON_PT = 0.5

# A finding exits 3, a status Python never gives of its own accord: it exits 1 for an exception
# nothing caught and for a script it cannot parse, as a Python older than this file's syntax
# does, and 2 when it cannot open the script. check reads only 3 as a finding, so a Python that
# fails before a line of the pass runs is never a finding a document has accepted.
FINDING = 3

def die(msg):
    """The pass could not run: exit 2, apart from FINDING, so check never takes a missing or
    broken tool for a finding a document has accepted."""
    print(msg, file=sys.stderr)
    sys.exit(2)

PDFTOTEXT = os.environ.get("PRESS_PDFTOTEXT", "pdftotext")
PDFTOCAIRO = os.environ.get("PRESS_PDFTOCAIRO", "pdftocairo")

# Poppler escapes &, < and > in word text, so a parser is correct here and a
# naive split is not. ElementTree is stdlib, which keeps this dependency-free.
import xml.etree.ElementTree as ET


def run(tool, var, args, pdf, what):
    """Run a poppler tool on the PDF, or say why it could not run."""
    try:
        subprocess.run([tool, *args], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        # Same reasoning as ink-margin.py: without this the failure is a bare
        # traceback naming neither the missing tool nor the remedy.
        die(f"press: overlap check needs poppler; {tool} not found\n"
            f"       set {var} to poppler's binary if it is not on PATH")
    except OSError as e:
        # FOUND but not runnable. Aiming PRESS_PDFTOTEXT at a shell script on
        # Windows raises WinError 193 rather than FileNotFoundError, and the bare
        # traceback for that names CreateProcess instead of the variable that
        # caused it. Measured while testing the branch above.
        die(f"press: {tool} could not be run ({e})\n"
            f"       {var} must name an executable, not a script")
    except subprocess.CalledProcessError:
        die(f"press: {tool} could not read {pdf} {what}")


def parse(text, tool, var, what):
    """XML a poppler tool wrote, or say it is not usable."""
    try:
        return ET.fromstring(text)
    except ImportError:
        # Importing ElementTree always succeeds; a Python built without expat fails here,
        # at the first parse, and its traceback would name neither the check nor a remedy.
        # The pass did not run, which is not a page with nothing on it: exit 2, never 0.
        die("press: the line-overlap check needs a python with an XML parser (expat); this one\n"
            "       has none: set PRESS_PYTHON to one that has")
    except ET.ParseError as e:
        # A truncated or non-XML answer means the binary is not producing what it
        # should, which is a tooling fault rather than a document one. A bare
        # ParseError traceback names neither the cause nor the remedy.
        die(f"press: {tool} did not return usable {what} ({e})\n"
            f"       set {var} to poppler's {pathlib.Path(tool).stem} if it is not on PATH")


def words_by_page(pdf, tmp):
    """[(xMin, xMax, yMin, yMax, text)] per page: the words, to name a finding by."""
    out = pathlib.Path(tmp) / "layout.xml"
    run(PDFTOTEXT, "PRESS_PDFTOTEXT", ["-bbox-layout", pdf, str(out)], pdf, "as text")
    xml = out.read_text(encoding="utf-8", errors="replace")
    # Namespaced by poppler; strip it rather than carry a prefix everywhere.
    root = parse(re.sub(r'\sxmlns="[^"]+"', "", xml, count=1), PDFTOTEXT, "PRESS_PDFTOTEXT",
                 "-bbox-layout XML")
    for page in root.iter("page"):
        yield [tuple(float(w.get(k)) for k in ("xMin", "xMax", "yMin", "yMax")) + (w.text,)
               for w in page.iter("word") if (w.text or "").strip()]


# --- Each glyph as drawn, from pdftocairo's SVG ---------------------------------------------

SVG = "{http://www.w3.org/2000/svg}"
HREFS = ("{http://www.w3.org/1999/xlink}href", "href")
NUM = r"[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?"
IDENTITY = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
# Not drawn where they stand: definitions, clips, masks and paints are drawn only through a
# reference, and a glyph only through a <use>.
UNDRAWN = {"defs", "clipPath", "mask", "pattern", "symbol", "marker", "linearGradient",
           "radialGradient", "style", "title", "desc", "metadata"}


def mul(m, n):
    """m after n, as SVG composes a transform list: the point goes through n, then m."""
    a, b, c, d, e, f = m
    A, B, C, D, E, F = n
    return (a * A + c * B, b * A + d * B, a * C + c * D, b * C + d * D,
            a * E + c * F + e, b * E + d * F + f)


def at(m, x, y):
    return (m[0] * x + m[2] * y + m[4], m[1] * x + m[3] * y + m[5])


def transform(s):
    """An SVG transform list, as one matrix."""
    m = IDENTITY
    for name, args in re.findall(r"(\w+)\s*\(([^)]*)\)", s or ""):
        v = [float(x) for x in re.findall(NUM, args)]
        if name == "matrix" and len(v) == 6:
            n = tuple(v)
        elif name == "translate" and v:
            n = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif name == "scale" and v:
            n = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif name == "rotate" and v:
            r = math.radians(v[0])
            n = (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0)
            if len(v) == 3:
                n = mul(mul((1, 0, 0, 1, v[1], v[2]), n), (1, 0, 0, 1, -v[1], -v[2]))
        elif name == "skewX" and v:
            n = (1, 0, math.tan(math.radians(v[0])), 1, 0, 0)
        elif name == "skewY" and v:
            n = (1, math.tan(math.radians(v[0])), 0, 1, 0, 0)
        else:
            die(f"press: {PDFTOCAIRO} drew a transform the line-overlap check does not read: "
                f"{name}({args})")
        m = mul(m, n)
    return m


def outline(d):
    """Points on a path's outline: each segment's ends, and three points along each curve.
    cairo writes absolute M, L, C and Z; the rest of SVG's path commands are read too."""
    toks = re.findall(r"[A-Za-z]|" + NUM, d)
    pts, i, cmd = [], 0, None
    x = y = sx = sy = 0.0

    def take(n):
        nonlocal i
        v = [float(t) for t in toks[i:i + n]]
        i += n
        return v if len(v) == n else None

    def along(ctrl):
        # A Bézier curve's points at a quarter, a half and three quarters of the way: its
        # control points weighed by the Bernstein polynomials, 1 2 1 for a quadratic and
        # 1 3 3 1 for a cubic.
        k = len(ctrl) - 1
        weights = (1, 2, 1) if k == 2 else (1, 3, 3, 1)
        for t in (0.25, 0.5, 0.75):
            pts.append(tuple(sum(w * (1 - t) ** (k - j) * t ** j * p[a]
                                 for j, (w, p) in enumerate(zip(weights, ctrl))) for a in (0, 1)))
    while i < len(toks):
        if toks[i].isalpha():
            cmd = toks[i]
            i += 1
            if cmd in "Zz":
                x, y = sx, sy
            continue
        if cmd is None:
            i += 1
            continue
        ox, oy = (x, y) if cmd.islower() else (0.0, 0.0)
        c = cmd.upper()
        n = {"M": 2, "L": 2, "T": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "A": 7}.get(c)
        v = take(n) if n else None
        if v is None:
            break
        if c == "H":
            x = ox + v[0]
        elif c == "V":
            y = oy + v[0]
        elif c == "C":
            along([(x, y), (ox + v[0], oy + v[1]), (ox + v[2], oy + v[3]), (ox + v[4], oy + v[5])])
            x, y = ox + v[4], oy + v[5]
        elif c == "Q":
            along([(x, y), (ox + v[0], oy + v[1]), (ox + v[2], oy + v[3])])
            x, y = ox + v[2], oy + v[3]
        else:
            x, y = ox + v[-2], oy + v[-1]
        if c == "M":
            sx, sy = x, y
            cmd = "l" if cmd == "m" else "L"
        pts.append((x, y))
    return pts


def hull(pts):
    """The convex hull, counter-clockwise (Andrew's monotone chain)."""
    pts = sorted(set(pts))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, hi = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(hi) >= 2 and cross(hi[-2], hi[-1], p) <= 0:
            hi.pop()
        hi.append(p)
    return lo[:-1] + hi[:-1]


def depth(P, Q):
    """How far two convex polygons overlap: the least overlap of their shadows across any
    edge of either, which is how far one must move to clear the other; 0 where they part."""
    best = math.inf
    for poly in (P, Q):
        n = len(poly)
        if n < 3:
            return 0.0
        for k in range(n):
            (x0, y0), (x1, y1) = poly[k], poly[(k + 1) % n]
            ax, ay = y0 - y1, x1 - x0
            size = math.hypot(ax, ay)
            if size == 0:
                continue
            ax, ay = ax / size, ay / size
            p = [ax * x + ay * y for x, y in P]
            q = [ax * x + ay * y for x, y in Q]
            o = min(max(p), max(q)) - max(min(p), min(q))
            if o <= 0:
                return 0.0
            best = min(best, o)
    return 0.0 if best == math.inf else best


def font_of(glyph_id):
    """cairo names a glyph by its font and its number in it: glyph-0-12 (cairo 1.18), glyph0-12
    (1.16). Its font is a face at a size and a slant, so text at a slant has a font of its own."""
    return glyph_id.rsplit("-", 1)[0]


def glyphs_by_page(pdf, tmp):
    """[(font, origin, hull, run)] per page, each glyph as drawn, in page points and in the order
    drawn; run is the group cairo drew it in."""
    out = pathlib.Path(tmp) / "page.svg"
    run(PDFTOCAIRO, "PRESS_PDFTOCAIRO", ["-svg", pdf, str(out)], pdf, "as SVG")
    root = parse(out.read_text(encoding="utf-8", errors="replace"), PDFTOCAIRO,
                 "PRESS_PDFTOCAIRO", "SVG")
    shapes = {}
    for el in root.iter():
        gid = el.get("id") or ""
        if gid.startswith("glyph") and el.tag in (SVG + "g", SVG + "symbol"):
            base = transform(el.get("transform"))
            pts = []
            for p in el.iter(SVG + "path"):
                m = mul(base, transform(p.get("transform")))
                pts += [at(m, x, y) for x, y in outline(p.get("d") or "")]
            shapes[gid] = hull(pts)
    # cairo writes a document of more than one page as a pageSet of pages.
    for top in [p for p in root.iter(SVG + "page")] or [root]:
        glyphs = []

        def walk(el, m, group):
            tag = el.tag.replace(SVG, "")
            if tag in UNDRAWN:
                return
            m = mul(m, transform(el.get("transform")))
            if tag == "use":
                ref = next((el.get(h) for h in HREFS if el.get(h)), "")[1:]
                if len(shapes.get(ref, ())) >= 3:
                    m = mul(m, (1, 0, 0, 1, float(el.get("x") or 0), float(el.get("y") or 0)))
                    glyphs.append((font_of(ref), at(m, 0, 0),
                                   [at(m, x, y) for x, y in shapes[ref]], group))
                return
            for k in el:
                walk(k, m, el if tag == "g" else group)
        walk(top, IDENTITY, None)
        yield glyphs


def lines(glyphs):
    """The glyphs on each baseline. A font's baseline runs the way its glyphs advance, read from
    the steps between them in a group cairo drew; a font with no step to read is upright."""
    angles = {}
    for (fa, oa, _, ga), (fb, ob, _, gb) in zip(glyphs, glyphs[1:]):
        if fa == fb and ga is gb:
            dx, dy = ob[0] - oa[0], ob[1] - oa[1]
            if math.hypot(dx, dy) > 0.1:
                angles.setdefault(fa, []).append(math.degrees(math.atan2(dy, dx)) % 180)
    way = {}
    for font, seen in angles.items():
        # The way most steps go, to the half degree; a step from one line to the next does not.
        by = {}
        for a in seen:
            by.setdefault(round(a * 2) / 2 % 180, []).append(a)
        most = max(by.values(), key=len)
        way[font] = sum(most) / len(most)
    keyed = []
    for g in glyphs:
        a = way.get(g[0], 0.0)
        r = math.radians(a)
        keyed.append((round(a * 2) / 2 % 180, -math.sin(r) * g[1][0] + math.cos(r) * g[1][1], g))
    keyed.sort(key=lambda k: (k[0], k[1]))
    out, last = [], None
    for a, off, g in keyed:
        # Origins within 0.05pt of the same baseline are on it: typst sets a line's glyphs on
        # one, and cairo writes their places to the millionth of a point.
        if last is None or a != last[0] or off - last[1] > 0.05:
            out.append([])
        out[-1].append(g)
        last = (a, off)
    return out


def box(points):
    xs, ys = [p[0] for p in points], [p[1] for p in points]
    return min(xs), max(xs), min(ys), max(ys)


def meet(a, b):
    """How far two boxes share each axis."""
    return min(a[1], b[1]) - max(a[0], b[0]), min(a[3], b[3]) - max(a[2], b[2])


def collisions(groups):
    """(overlap, i, j) for each pair of lines with glyphs drawn on each other's. A box around
    each line, then around each glyph, rules out at once what cannot meet; an overlap past the
    floor needs more than the floor on both axes."""
    boxed = []
    for grp in groups:
        gb = [(box(h), h) for _, _, h, _ in grp]
        boxed.append((box([p for b, _ in gb for p in ((b[0], b[2]), (b[1], b[3]))]), gb))
    for i in range(len(boxed)):
        for j in range(i + 1, len(boxed)):
            (bi, gi), (bj, gj) = boxed[i], boxed[j]
            mx, my = meet(bi, bj)
            if mx <= EPSILON_PT or my <= EPSILON_PT:
                continue
            worst = 0.0
            for b1, h1 in gi:
                for b2, h2 in gj:
                    ox, oy = meet(b1, b2)
                    if ox > EPSILON_PT and oy > EPSILON_PT:
                        worst = max(worst, depth(h1, h2))
            if worst > EPSILON_PT:
                yield worst, i, j


def spelled(line, words):
    """The words a line's glyphs are in, as pdftotext reads them, to name it by. Where text lies
    on text, a glyph's centre is in a word of each line; of the word boxes around it, the one
    whose centre lies nearest the line's own axis is the line's, measured across the line, the
    way its baseline runs, since the other line's words lie off it by as far as they collided."""
    origins = sorted(o for _, o, _, _ in line)
    (ax, ay), (bx, by) = origins[0], origins[-1]
    if math.hypot(bx - ax, by - ay) > 1:
        r = math.atan2(by - ay, bx - ax)
    else:
        r = 0.0
    across = lambda x, y: -math.sin(r) * x + math.cos(r) * y
    centres = []
    for _, _, h, _ in line:
        x0, x1, y0, y1 = box(h)
        centres.append(((x0 + x1) / 2, (y0 + y1) / 2))
    axis = sorted(across(x, y) for x, y in centres)[len(centres) // 2]
    seen = []
    for cx, cy in centres:
        inside = [w for w in words if w[0] <= cx <= w[1] and w[2] <= cy <= w[3]]
        if inside:
            w = min(inside, key=lambda w: abs(across((w[0] + w[1]) / 2, (w[2] + w[3]) / 2) - axis))
            if w not in seen:
                seen.append(w)
    if not seen:
        x0, _, y0, _ = box([p for _, _, h, _ in line for p in h])
        return f"(text at {x0:.0f}, {y0:.0f}pt)"
    return " ".join(w[4] for w in seen)


def main():
    # A second argument names the PDF in findings, when the one read is a copy of it: check reads
    # a copy with its scans hidden (lib/parts.typ's scan()), and reports against the document's PDF.
    pdf = sys.argv[1]
    name = sys.argv[2] if len(sys.argv) > 2 else pdf
    rc = 0
    with tempfile.TemporaryDirectory() as tmp:
        words = list(words_by_page(pdf, tmp))
        for n, glyphs in enumerate(glyphs_by_page(pdf, tmp), 1):
            found = lines(glyphs)
            on = words[n - 1] if n <= len(words) else []
            for ov, i, j in collisions(found):
                # Upper is the line that starts higher on the page.
                a, b = sorted((found[i], found[j]),
                              key=lambda ln: box([p for _, _, h, _ in ln for p in h])[2])
                print(f"press: {name} page {n} prints text on text — {ov:.2f}pt overlap",
                      file=sys.stderr)
                print(f"    upper: {spelled(a, on)[:72]}", file=sys.stderr)
                print(f"    lower: {spelled(b, on)[:72]}", file=sys.stderr)
                rc = FINDING
    return rc


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SystemExit:
        raise
    except Exception as e:                    # a crash is the pass failing to run, never a finding
        die(f"press: {pathlib.Path(sys.argv[0]).name} failed: {e!r}")
