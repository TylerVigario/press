#!/bin/sh
# recipe-ref.sh — a recipe card points into its reference by page, as a brief does.
#
#   sh .github/recipe-ref.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. recipe starts a card's
# reference on a page of its own, and a step points there with typst's page reference,
# #ref(<label>, form: "page"), which typst refuses where the pages are not numbered.
# .github/recipe-ref.typ must compile, and its pointer print "see page 2".
set -eu
cd "$(dirname "$0")/.."

fail() { echo "recipe-ref: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/recipe-ref.typ "$tmp/probe.pdf" \
    || fail "a recipe card with a page reference does not compile"
pdftotext "$tmp/probe.pdf" - | grep -qF 'If they stay hard, see page 2.' \
    || fail "the card's pointer does not print \"see page 2\": $(pdftotext "$tmp/probe.pdf" - | grep 'stay hard')"
echo "recipe-ref: a recipe card points into its reference by page"
