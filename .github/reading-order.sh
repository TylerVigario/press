#!/bin/sh
# reading-order.sh — a résumé reads in the order it prints: the name, the headline and the
# contact line, then each role with its organisation and its dates, before the next role.
#
#   sh .github/reading-order.sh
#
# Run by CI's audit job, which has poppler. A résumé is read first by an applicant-tracking
# parser, and a role read beside another role's dates is a wrong work history. .github/resume.typ
# holds the entries a résumé has. Its text is read twice, laid out as pdftotext -layout lays it,
# and in the order it is written, as pdftotext -raw reads it; each must give the strings below in
# order. Then the layout itself: a wrapped role's dates sit on its last line, and dates that do
# not fit there take a line of their own, still at the right.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "reading-order: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

pdf=$tmp/resume.pdf
typst compile --root . --font-path fonts --ignore-system-fonts .github/resume.typ "$pdf"
for mode in -layout -raw; do
    # The text as one line, each run of spaces one space, so a wrapped role reads as one.
    rest=$(pdftotext "$mode" "$pdf" - | tr -s ' \n\f' '   ')
    while IFS= read -r want; do
        case $rest in
            *"$want"*) rest=${rest#*"$want"} ;;
            *) fail "read with pdftotext $mode, \"$want\" is missing or out of order" ;;
        esac
    done <<'EOF'
Pat Example
Network and systems
Town, ST
pat@example.com
EXPERIENCE
Network technician
Valley Broadband
2021 – present
Senior field operations supervisor
Organisation Name Incorporated
2017 – 2021
Technician with a role long enough
The Edge Now
Jan 2014 – Dec 2016
Field technician
2012 – 2014
Organisation, Town, ST
EOF
    echo "reading-order: read with pdftotext $mode, the résumé reads in the order it prints"
done

pdftotext -layout "$pdf" "$tmp/layout.txt"
grep -q 'Incorporated  *2017 – 2021$' "$tmp/layout.txt" \
    || fail "a wrapped role's dates are not on its last line"
grep -qE '^ {40,}Jan 2014 – Dec 2016$' "$tmp/layout.txt" \
    || fail "dates that do not fit on a role's last line are not on a line of their own, at the right"
echo "reading-order: a wrapped role's dates are on its last line, or on their own at the right"
