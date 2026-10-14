#!/usr/bin/env python3
"""Report the smallest distance from any ink to any paper edge, per page.

Exists because a document can overflow the printable area silently: typst has
no concept of a printer's unprintable band, so the failure only appears on
paper, after the sheet is in your hand.

Reads PGM pages by rendering via pdftoppm, so it needs poppler — the same
dependency `check` already has — plus a Python to run this file.

`check` finds that interpreter by EXECUTING a candidate rather than by resolving
the name `python3`, and accepts `python`. On Windows the name proves nothing in
either direction: the App Execution Alias puts a zero-byte `python3` on PATH that
answers `command -v` and then exits 49, and disabling that alias leaves a working
`python` with no `python3` at all. Where neither is found, `check` skips this pass
rather than failing, because the font checks are worth having on their own.

PRESS_PYTHON and PRESS_PDFTOPPM name either executable directly, for the same
reason PRESS_PDFTOTEXT exists: on Windows PATH is not the contributor's to order.
"""
import os, subprocess, sys, tempfile, pathlib

DPI = 150

# The third poppler binary, and the one PRESS_PDFTOTEXT / PRESS_PDFFONTS forgot.
# Same reasoning as those two: on Windows a contributor cannot order PATH, so the
# lever has to be the executable's name. Unlike the other two this is an ABSENCE
# problem rather than a wrong-implementation one — Git for Windows bundles Xpdf's
# pdftotext but no pdftoppm at all — so there is nothing to assert against, only
# something to find.
PDFTOPPM = os.environ.get("PRESS_PDFTOPPM") or "pdftoppm"

def pages(pdf, tmp):
    try:
        subprocess.run([PDFTOPPM, "-r", str(DPI), "-gray", pdf, f"{tmp}/p"],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        # Without this the failure is a bare Python traceback ending in
        # "[WinError 2] The system cannot find the file specified", which names
        # neither the missing tool nor the remedy.
        sys.exit(f"press: printable-area check needs poppler; {PDFTOPPM} not found\n"
                 f"       set PRESS_PDFTOPPM to poppler's binary if it is not on PATH")
    except OSError as e:
        # Found but not runnable, as line-overlap.py handles for PRESS_PDFTOTEXT: on
        # Windows a script raises WinError 193, and the bare traceback names CreateProcess
        # instead of the variable that caused it.
        sys.exit(f"press: {PDFTOPPM} could not be run ({e})\n"
                 f"       PRESS_PDFTOPPM must name an executable, not a script")
    except subprocess.CalledProcessError:
        sys.exit(f"press: {PDFTOPPM} could not render {pdf}")
    return sorted(pathlib.Path(tmp).glob("p-*.pgm"))

def read_pgm(path):
    d = path.read_bytes()
    fields, i = [], 0
    while len(fields) < 4:
        while d[i:i+1].isspace(): i += 1
        if d[i:i+1] == b"#":
            while d[i:i+1] not in (b"\n", b""): i += 1
            continue
        j = i
        while not d[j:j+1].isspace(): j += 1
        fields.append(d[i:j]); i = j
    return int(fields[1]), int(fields[2]), d[i+1:]

def clearance(path):
    w, h, px = read_pgm(path)
    minx, maxx, miny, maxy = w, -1, h, -1
    for y in range(h):
        row = px[y*w:(y+1)*w]
        # 230 rather than 255: anti-aliased edges and the palest tints are ink.
        xs = [x for x, v in enumerate(row) if v < 230]
        if xs:
            miny = min(miny, y); maxy = y
            minx = min(minx, xs[0]); maxx = max(maxx, xs[-1])
    if maxx < 0:
        return None                      # blank page, nothing to clip
    return min(minx, w-1-maxx, miny, h-1-maxy) / DPI

def main():
    pdf, floor = sys.argv[1], float(sys.argv[2])
    rc = 0
    with tempfile.TemporaryDirectory() as tmp:
        for n, page in enumerate(pages(pdf, tmp), 1):
            c = clearance(page)
            if c is None:
                continue
            if c < floor:
                print(f"press: {pdf} page {n} has ink {c:.2f}in from a paper edge "
                      f"(floor {floor:.2f}in) — it will clip when printed at actual size",
                      file=sys.stderr)
                rc = 1
    return rc

if __name__ == "__main__":
    sys.exit(main())
