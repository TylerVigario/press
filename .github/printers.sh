#!/bin/sh
# printers.sh — press's own calibration is the median of the printers printers.csv records at
# normal quality, each by its latest printing; printer() gives it, each printer printers.csv
# records and the median in economy mode, and stops on a printer or a mode it does not record;
# printers.csv stops the build on a row that is not as PRINTERS.md says; and the audit holds a
# document that declares no bands of its own to press's own at each edge.
#
#   sh .github/printers.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler and a Python. press reads
# the printers.csv beside its lib.typ, so each case is set in a copy of press with a printers.csv
# of its own: press's, its header alone (none); three printers at normal quality and two in
# economy mode, one printed twice in each, earlier after later, quoted in one row and not the
# other, and twice on one date, one quoted for the comma in its name, and the economy bands
# unlike the normal ones (recorded); or two at normal quality, written as a spreadsheet may
# write them, with CRLF line endings and one row's every word quoted (even).
# .github/printers.typ asserts what each gives, or makes the call a case is named for.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "printers: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

tree=$tmp/press
mkdir -p "$tree/.github"
cp -R lib lib.typ press.toml tools fonts "$tree/"
cp .github/printers.typ .github/printers-floor.typ "$tree/.github/"
head=$(sed -n 1p printers.csv)

# set <none|recorded|even|row>: the copy's printers.csv; row, the recorded ones and one more.
set_csv() {
    case $1 in
        none) cp printers.csv "$tree/printers.csv" ;;
        even) printf '%s\r\n' "$head" \
                  '"Alpha A1","normal","2026-12-01","0.11.0",4,17,6,6,6,1.2,0.5,0.6,0.5,0.5' \
                  '"Beta, B2",normal,2026-11-02,0.10.0,3,12,5,5,7,1.1,0.4,0.5,0.6,0.4' \
                  > "$tree/printers.csv" ;;
        *) printf '%s\n' "$head" \
               'Alpha A1,normal,2026-12-01,0.11.0,4,17,6,6,6,1.2,0.5,0.6,0.5,0.5' \
               '"Alpha A1",normal,2026-11-01,0.10.0,9,9,9,9,9,9,9,9,9,9' \
               '"Beta, B2",normal,2026-11-02,0.10.0,3,12,5,5,7,1.1,0.4,0.5,0.6,0.4' \
               'Gamma G3,normal,2026-11-03,0.10.0,5,14,4,7,5,1.3,0.6,0.4,0.4,0.6' \
               'Alpha A1,economy,2026-12-01,0.11.0,4,17,6,6,8,1.5,0.6,0.7,0.6,0.6' \
               'Gamma G3,economy,2026-11-03,0.10.0,6,15,5,8,9,1.6,0.8,0.6,0.5,0.8' \
               'Gamma G3,economy,2026-11-03,0.10.0,6,16,5,8,10,1.7,0.8,0.6,0.5,0.8' \
               > "$tree/printers.csv"
           [ "$1" = recorded ] || printf '%s\n' "$2" >> "$tree/printers.csv" ;;
    esac
}
build() {
    (cd "$tree" && typst compile --root . --font-path fonts --ignore-system-fonts \
        --input case="$1" .github/printers.typ "$tmp/out.pdf") > "$tmp/log" 2>&1
}
# passes <printers.csv> <case>: the case builds, its assertions held.
passes() {
    set_csv "$1"
    build "$2" || { cat "$tmp/log" >&2; fail "$2, with printers.csv $1, does not build"; }
    echo "printers: $2 holds, with printers.csv $1"
}
# stops <printers.csv> <case> <words> [row]: the build stops, saying the words.
stops() {
    set_csv "$1" "${4:-}"
    ! build "$2" || fail "$2, with printers.csv $1, builds"
    grep -qF -- "$3" "$tmp/log" || { cat "$tmp/log" >&2; fail "$2 stops, but not saying: $3"; }
    echo "printers: $2 stops, saying: $3"
}

passes none none
passes recorded recorded
passes even even
stops none unknown 'printers.csv records no printer "Delta D4"; it records none yet'
stops none no-economy 'printers.csv records no printer in economy mode'
stops recorded unknown \
    'printers.csv records no printer "Delta D4"; it records "Alpha A1", "Beta, B2" and "Gamma G3"'
stops recorded unrecorded-mode 'printers.csv records "Beta, B2" in normal mode, not economy'
stops recorded mode "printer()'s mode is \"normal\" or \"economy\"; got \"draft\""
stops recorded two 'printer() takes one printer, by its make and model; got "Alpha A1", "Beta, B2"'
stops recorded named 'printer() takes no argument named "model"'
stops recorded string 'printer() takes a printer by its make and model, a string; got 1'

# A row that is not as PRINTERS.md says, after the recorded ones.
stops row recorded 'edge-bottom-mm takes a number, written bare; got "17mm"' \
    'Delta D4,normal,2026-12-01,0.11.0,4,17mm,6,6,6,1.2,0.5,0.6,0.5,0.5'
stops row recorded 'mode is normal or economy; got "Economy"' \
    'Delta D4,Economy,2026-12-01,0.11.0,4,17,6,6,6,1.2,0.5,0.6,0.5,0.5'
stops row recorded 'printed takes the date, as 2026-11-20; got "12/01/2026"' \
    'Delta D4,normal,12/01/2026,0.11.0,4,17,6,6,6,1.2,0.5,0.6,0.5,0.5'
stops row recorded 'press takes the version in the sheet'"'"'s header; got "v0.11"' \
    'Delta D4,normal,2026-12-01,v0.11,4,17,6,6,6,1.2,0.5,0.6,0.5,0.5'
stops row recorded 'ink takes a contrast on white, from 1 to 21; got 0.5' \
    'Delta D4,normal,2026-12-01,0.11.0,4,17,6,6,0.5,1.2,0.5,0.6,0.5,0.5'
stops row recorded "printers.csv's row 9, \" Delta D4\": printer takes the printer's make and model" \
    ' Delta D4,normal,2026-12-01,0.11.0,4,17,6,6,6,1.2,0.5,0.6,0.5,0.5'
# A column renamed.
set_csv none
sed -i.bak '1s/rule-ink-pt$/ink-pt/' "$tree/printers.csv"
! build none || fail "a printers.csv with a column renamed builds"
grep -qF "printers.csv's columns are printer,mode,printed" "$tmp/log" \
    || { cat "$tmp/log" >&2; fail "a printers.csv with a column renamed stops, but not naming its columns"; }
echo "printers: a printers.csv with a column renamed stops, naming its columns"

# The audit's floor at each edge, top, bottom, left and right, where a document declares no bands:
# as it says, to two places, of the ink 0.1in from each edge in .github/printers-floor.typ.
for c in none:0.48,0.48,0.48,0.48 recorded:0.16,0.55,0.20,0.24 even:0.14,0.57,0.22,0.22; do
    csv=${c%%:*} want=${c#*:}
    set_csv "$csv"
    (cd "$tree" && sh tools/check.sh .github/printers-floor.typ "$tmp/floor.pdf" . --root . \
        --font-path fonts --ignore-system-fonts) > "$tmp/log" 2>&1 || true
    got=$(for e in top bottom left right; do
        sed -n "s/.* from its $e edge, inside the \([0-9.]*\)in band .*/\1/p" "$tmp/log" | head -n 1
    done | paste -sd, -)
    [ "$got" = "$want" ] || { cat "$tmp/log" >&2; fail "with printers.csv $csv, the audit holds a document that declares no bands to $got at its top, bottom, left and right edges, where press's own are $want"; }
    echo "printers: with printers.csv $csv, the audit's floor is press's own, $want"
done
echo "printers: press's own calibration is the median of the printers printers.csv records, and printer() gives each"
