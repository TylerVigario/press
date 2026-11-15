#!/bin/sh
# steps.sh — steps() is one list: a tagged PDF marks a run of steps as one list, an item for each
# step, apart from a list after it, and each step's number is beside its title.
#
#   sh .github/steps.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python. A screen
# reader finds a list, and moves from item to item, by the PDF's tags: a list is L, each item LI,
# its number Lbl and its text LBody. typst joins numbered items into one list only where they
# share one numbering, so steps given one by one, each numbered for itself, are a list each.
# .github/steps.typ holds three steps and then a list of typst's own; pdfinfo -struct prints the
# tags, each a line, indented by depth.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "steps: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

py=${PRESS_PYTHON:-python3}
typst compile --root . --font-path fonts --ignore-system-fonts .github/steps.typ "$tmp/steps.pdf"
# poppler's warnings on typst's table attributes go to stderr, apart from the tags.
pdfinfo -struct "$tmp/steps.pdf" 2>/dev/null > "$tmp/tags"
lists=$("$py" - "$tmp/tags" <<'PY'
import re, sys
# Each list, as the number of items directly in it, in the order they print.
lines = [l.rstrip("\n") for l in open(sys.argv[1]) if l.strip()]
depth = lambda l: len(l) - len(l.lstrip(" "))
tag = lambda l: re.match(r"\s*(\S+)", l).group(1)
counts = []
for i, l in enumerate(lines):
    if tag(l) == "L":
        d, n = depth(l), 0
        for m in lines[i + 1:]:
            if depth(m) <= d:
                break
            if tag(m) == "LI" and depth(m) == d + 2:
                n += 1
        counts.append(n)
print(" ".join(map(str, counts)))
PY
)
[ "$lists" = "3 2" ] \
    || fail "the three steps and the list after them are tagged as lists of $lists items, not one of 3 and one of 2"
echo "steps: a run of steps is one tagged list, an item for each step, apart from the list after it"

pdftotext -layout "$tmp/steps.pdf" "$tmp/layout.txt"
for line in '1 Shut the water off' '2 Open the box' '3 Read the meter'; do
    grep -qE "^ *$(printf '%s' "$line" | sed 's/ /  */')$" "$tmp/layout.txt" \
        || fail "a step's number is not beside its title: \"$line\""
done
echo "steps: each step's number is beside its title"
