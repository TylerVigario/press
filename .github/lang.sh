#!/bin/sh
# lang.sh — a document's language is its own, in every template: given at the document's start
# or as the template's lang, its words and its PDF are in it; given under the template's show
# rule, its words are; and given nowhere, both are in typst's English.
#
#   sh .github/lang.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python.
# .github/lang.typ sets a line of Spanish with a quotation in it, in the template --input
# template= names, its language given where --input where= says. typst curls a quotation by the
# language, “…” in English and «…» in Spanish, so pdftotext reads the language its words were set
# in; and the PDF names its own language, which screen readers and translation software go by,
# as /Lang in its catalogue, which may sit in a compressed stream. typst takes the PDF's language
# from the first content it meets, so one given under the show rule, after a template's head,
# reaches the words but not always the PDF: typst's accessibility guide gives the language at the
# document's start, and press's templates take it as `lang`.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "lang: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

py=${PRESS_PYTHON:-python3}
# pdf_lang <pdf>: the language the PDF names itself in, its catalogue's /Lang.
pdf_lang() {
    "$py" - "$1" <<'PY'
import re, sys, zlib
data = open(sys.argv[1], "rb").read()
found = re.findall(rb"/Lang\s*\(([^)]*)\)", data)
for m in re.finditer(rb"stream\r?\n", data):
    try:
        found += re.findall(rb"/Lang\s*\(([^)]*)\)", zlib.decompress(data[m.end():data.find(b"endstream", m.end())]))
    except zlib.error:
        pass
print(found[0].decode() if found else "")
PY
}
english='“a tiempo”'
spanish='«a tiempo»'

for t in base brief letter recipe resume; do
    for where in start template under none; do
        pdf=$tmp/$t-$where.pdf
        typst compile --root . --font-path fonts --ignore-system-fonts --input template="$t" \
            --input where="$where" .github/lang.typ "$pdf"
        words=$(pdftotext "$pdf" - | tr -d '\n')
        named=$(pdf_lang "$pdf")
        case $where in
            none)
                case $words in *"$english"*) ;; *) fail "$t, given no language, sets its words in another than English: $words" ;; esac
                [ "$named" = en ] || fail "$t, given no language, names its PDF's language \"$named\", not en" ;;
            *)
                case $words in *"$spanish"*) ;; *) fail "$t, given Spanish ($where), sets its words in another: $words" ;; esac
                [ "$where" = under ] || [ "$named" = es ] \
                    || fail "$t, given Spanish ($where), names its PDF's language \"$named\", not es" ;;
        esac
    done
done
echo "lang: a template keeps the document's language, given at its start or as its lang"
