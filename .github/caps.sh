#!/bin/sh
# caps.sh — every label press uppercases keeps its case under caps: false, so "pH" is not "PH".
#
#   sh .github/caps.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/caps.typ sets a
# unit, a callout, a panel, an addendum, an eyebrow and a template's two headings, each labelled
# "pH" and its name, under brief, recipe and resume. With caps: false each label prints as written;
# by default each prints in capitals. pdftotext reads a tracked label's letters with spaces
# between some of them, so the text is read with its spaces taken out.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "caps: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

labels="heading subheading unit callout panel addendum eyebrow"
for template in brief recipe resume; do
    for caps in false true; do
        typst compile --root . --font-path fonts --ignore-system-fonts --input "template=$template" \
            --input "caps=$caps" .github/caps.typ "$tmp/probe.pdf"
        text=$(pdftotext "$tmp/probe.pdf" - | tr -d ' \n')
        for label in $labels; do
            want=pH$label
            [ "$caps" = false ] || want=$(printf 'PH%s' "$label" | tr '[:lower:]' '[:upper:]')
            case $text in
                *"$want"*) ;;
                *) fail "$template, caps: $caps: the $label's label is not $want" ;;
            esac
        done
    done
done
echo "caps: every label press uppercases keeps its case under caps: false, under every template"
