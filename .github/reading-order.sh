#!/bin/sh
# reading-order.sh — a résumé reads in the order it prints: the name, the headline and the
# contact line, then each role with its organisation and its dates, before the next role.
#
#   sh .github/reading-order.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. A résumé is read first by an
# applicant-tracking parser, and a role read beside another role's dates is a wrong work history.
# .github/resume.typ holds the entries a résumé has, set as entry() sets them, the dates in the
# line's flow after the organisation, and with flush: true, at the right of the line. entry()'s
# own is read three ways: as plain pdftotext reads it, grouping the page's text by where it
# stands, which reads dates set at the right after every role; laid out, as pdftotext -layout
# lays it; and in the order it is written, as pdftotext -raw reads it. flush: true is read the
# last two ways, the two that read it in order. Each must give the strings below in order. Then
# the layout itself: a role's dates follow its organisation, whole, on its line or the next; and
# with flush: true, a wrapped role's dates sit on its last line, and dates that do not fit there
# take a line of their own, still at the right.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "reading-order: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# text <mode> <pdf>: the page's text as pdftotext reads it, `plain` for no mode, as one line, each
# run of spaces one space, so a wrapped role reads as one.
text() {
    if [ "$1" = plain ]; then pdftotext "$2" -; else pdftotext "$1" "$2" -; fi | tr -s ' \n\f' '   '
}
# in_order <mode> <pdf> <what>: the strings on stdin, each found after the one before.
in_order() {
    rest=$(text "$1" "$2")
    while IFS= read -r want; do
        case $rest in
            *"$want"*) rest=${rest#*"$want"} ;;
            *) fail "$3, read with pdftotext $1, \"$want\" is missing or out of order" ;;
        esac
    done
    echo "reading-order: $3, read with pdftotext $1, reads in the order it prints"
}

for flush in false true; do
    typst compile --root . --font-path fonts --ignore-system-fonts --input flush=$flush \
        .github/resume.typ "$tmp/flush-$flush.pdf"
done
# Each role, then its organisation and dates, then its result, before the next role: dates read
# after the result under them are a role's dates read late.
head='Pat Example
Network and systems
Town, ST
pat@example.com
EXPERIENCE
Network technician
Valley Broadband
2021 – present
A result.
Senior field operations supervisor
Organisation Name Incorporated
2017 – 2021
A result.
Technician with a role long enough
The Edge Now
Jan 2014 – Dec 2016
A result.
Field technician'
for mode in plain -layout -raw; do
    printf '%s\n%s\n%s\n%s\n' "$head" 'Organisation, Town, ST' '2012 – 2014' 'A result.' \
        | in_order "$mode" "$tmp/flush-false.pdf" "a résumé"
done
for mode in -layout -raw; do
    printf '%s\n%s\n%s\n%s\n' "$head" '2012 – 2014' 'Organisation, Town, ST' 'A result.' \
        | in_order "$mode" "$tmp/flush-true.pdf" "a résumé with flush: true"
done

pdftotext -layout "$tmp/flush-false.pdf" "$tmp/layout.txt"
grep -q 'Valley Broadband · 2021 – present$' "$tmp/layout.txt" \
    || fail "a role's dates do not follow its organisation on its line"
grep -qE '^ *· Jan 2014 – Dec 2016$' "$tmp/layout.txt" \
    || fail "dates that do not fit after their organisation do not take the next line whole"
echo "reading-order: a role's dates follow its organisation, whole, on its line or the next"

pdftotext -layout "$tmp/flush-true.pdf" "$tmp/layout.txt"
grep -q 'Incorporated  *2017 – 2021$' "$tmp/layout.txt" \
    || fail "with flush: true, a wrapped role's dates are not on its last line"
grep -qE '^ {40,}Jan 2014 – Dec 2016$' "$tmp/layout.txt" \
    || fail "with flush: true, dates that do not fit on a role's last line are not on a line of their own, at the right"
echo "reading-order: with flush: true, a wrapped role's dates are on its last line, or on their own at the right"
