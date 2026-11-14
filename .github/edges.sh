#!/bin/sh
# edges.sh — a template set for a calibration keeps its ink clear of the printer's bands: given
# bands wider than press's own at every edge, each template widens its margins, so its ink, a
# header and a footer included, clears them; given press's own, it lays out as given none; and
# press's own calibration is the floor the audit takes where a document declares none.
#
#   sh .github/edges.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python.
# .github/edges.typ sets two pages or more in the template --input template= names, given the
# calibration --input calibration= names: none, press's own (own), or bands of 1in at every edge
# (wide), where press's own are 0.48in. Given none, each template prints ink inside 1in, so
# measuring the wide one bites, and a letter's page-two header clears its band only because the
# header keeps its distance from the body as its margin widens.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "edges: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

py=${PRESS_PYTHON:-python3}
build() {
    typst compile --root . --font-path fonts --ignore-system-fonts --input template="$1" \
        --input calibration="$2" .github/edges.typ "$tmp/$1-$2.pdf"
}
look() { pdftoppm -r 40 -gray "$1" | sha256sum; }
# margin <pdf> <floor>: the edge pass's status, 0 for ink clear of the floor and 3 for ink inside.
margin() { s=0; "$py" tools/ink-margin.py "$1" "$2" > "$tmp/out" 2>&1 || s=$?; echo "$s"; }

for t in base brief letter recipe resume; do
    for c in none own wide; do build "$t" "$c"; done
    pages=$(pdfinfo "$tmp/$t-wide.pdf" | sed -n 's/^Pages: *//p')
    [ "$pages" -ge 2 ] || fail "$t sets edges.typ on $pages page; the check measures a second page's header and footer"
    [ "$(margin "$tmp/$t-none.pdf" 1)" = 3 ] \
        || fail "$t, given no calibration, prints no ink inside 1in, so measuring it given 1in proves nothing"
    s=$(margin "$tmp/$t-wide.pdf" 1)
    [ "$s" = 0 ] || { cat "$tmp/out" >&2; fail "$t, given bands of 1in at every edge, prints ink inside them (status $s)"; }
    [ "$(look "$tmp/$t-own.pdf")" = "$(look "$tmp/$t-none.pdf")" ] \
        || fail "$t, given press's own calibration, lays out otherwise than given none"
done

# The audit's floor where a document declares no calibration is press's own, as a template
# records it for the audit.
floor=$(sed -n 's/^floor=//p' tools/check.sh)
[ -n "$floor" ] || fail "tools/check.sh sets no floor= for a document that declares no calibration"
# typst eval, or typst query before 0.15, which has no eval, as check.sh reads press's marks.
set -- --root . --font-path fonts --ignore-system-fonts --input template=brief --input calibration=none
marks=$(typst eval 'query(metadata).map(m => m.value)' --in .github/edges.typ "$@" 2>/dev/null \
    || typst query "$@" .github/edges.typ metadata --field value)
own=$(printf '%s\n' "$marks" | grep -o '"press-edges [^"]*"' | sed 's/^"press-edges //; s/"$//')
[ "$own" = "$floor $floor $floor $floor" ] \
    || fail "press's own calibration records its bands as $own, but the audit's floor where none is declared is $floor"
echo "edges: a template set for a calibration keeps its ink clear of the printer's bands"
