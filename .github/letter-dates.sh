#!/bin/sh
# letter-dates.sh — continued() dates each page by the letter it is a page of.
#
#   sh .github/letter-dates.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/letter-dates.typ
# holds two letters, each running onto a second page: page 2 is the first letter's, dated
# 1 January 2026, and page 4 the second's, dated 9 September 2026. continued() once read the
# document's last date onto every page, so the first letter's second page carried the second
# letter's date.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "letter-dates: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/letter-dates.typ "$tmp/probe.pdf"
pages=$(pdfinfo "$tmp/probe.pdf" | sed -n 's/^Pages: *//p')
[ "$pages" -eq 4 ] || fail "the two letters print on $pages pages, not 4; the check reads pages 2 and 4"
# head <page>: the first line of a page, its header.
head_of() { pdftotext -layout -f "$1" -l "$1" "$tmp/probe.pdf" - | grep -v '^[[:space:]]*$' | head -1; }
head_of 2 | grep -qF '1 January 2026' \
    || fail "the first letter's second page is not dated 1 January 2026: $(head_of 2)"
head_of 4 | grep -qF '9 September 2026' \
    || fail "the second letter's second page is not dated 9 September 2026: $(head_of 4)"
echo "letter-dates: continued() dates each page by the letter it is a page of"
