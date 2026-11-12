#!/bin/sh
# source-date.sh — a build with SOURCE_DATE_EPOCH set takes it for the current time, as the
# specification says (https://reproducible-builds.org/specs/source-date-epoch/): a new or changed
# page is stamped with it, an unchanged page keeps its stamp, or comes back to it where the stamp
# is later, and a value that is not a whole number of seconds stops the build.
#
#   sh .github/source-date.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. A scratch repository
# holds a copy of the kit under third_party/press and one brief, whose footer prints the stamp,
# built with build.sh in UTC:
#
#   · new at 1700000000, 2023-11-14 22:13 UTC, its footer and its PDF's own date that time;
#   · edited, at 1700003600, 23:13;
#   · unchanged with no SOURCE_DATE_EPOCH, keeping 23:13, from the build record or not;
#   · unchanged at 1700000000, earlier than its stamp, coming back to 22:13, though the build
#     record holds 23:13;
#   · set but empty, as if unset, keeping 22:13;
#   · at 1700000000.5, and at "soon", stopping with a line naming the variable.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "source-date: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$tmp/repo
mkdir -p "$repo/third_party/press" "$repo/docs"
cp -R lib.typ lib press.toml template calibration.typ fonts tools "$repo/third_party/press/"
note() {
    printf '#import "/third_party/press/lib.typ": *\n%s\n\n%s\n' \
        '#show: brief.with(title: [Note], author: "Sam Example")' "$1" > "$repo/docs/note.typ"
}
note "One line."
cd "$repo"

# build [env...]: build the document in UTC; prints build.sh's line, and its errors.
build() { env PRESS_TZ=UTC "$@" sh third_party/press/tools/build.sh docs/note.typ 2>&1; }
# expect <what> <status> <time> <build's line>: unchanged takes cached too, the build record's
# answer for a page that did not change.
expect() {
    case $4 in
        *"note.pdf: $2, "*"updated 2023-11-14 $3 UTC"*) ;;
        *"note.pdf: cached, "*"updated 2023-11-14 $3 UTC"*) [ "$2" = unchanged ] || {
            printf '%s\n' "$4" >&2; fail "$1 is cached, not $2"; } ;;
        *) printf '%s\n' "$4" >&2; fail "$1 is not $2 at 2023-11-14 $3 UTC" ;;
    esac
    echo "source-date: $1: $2, $3"
}

out=$(build SOURCE_DATE_EPOCH=1700000000) \
    || { printf '%s\n' "$out" >&2; fail "the first build failed"; }
expect "a new page at 1700000000" new 22:13 "$out"
pdftotext print/docs/note.pdf - | grep -q '2023-11-14 22:13 UTC' \
    || fail "the footer does not print 2023-11-14 22:13 UTC"
date=$(pdfinfo -isodates print/docs/note.pdf | sed -n 's/^CreationDate: *//p')
case $date in 2023-11-14T22:13:20*) ;; *) fail "the PDF's own date is $date, not 1700000000" ;; esac

note "Two lines."
out=$(build SOURCE_DATE_EPOCH=1700003600) \
    || { printf '%s\n' "$out" >&2; fail "the edited build failed"; }
expect "an edited page at 1700003600" changed 23:13 "$out"

out=$(build) || { printf '%s\n' "$out" >&2; fail "the build with no SOURCE_DATE_EPOCH failed"; }
expect "an unchanged page with no SOURCE_DATE_EPOCH" unchanged 23:13 "$out"

out=$(build SOURCE_DATE_EPOCH=1700000000) \
    || { printf '%s\n' "$out" >&2; fail "the clamped build failed"; }
expect "an unchanged page stamped later than SOURCE_DATE_EPOCH" unchanged 22:13 "$out"

out=$(build SOURCE_DATE_EPOCH=) \
    || { printf '%s\n' "$out" >&2; fail "the build with it empty failed"; }
expect "an unchanged page with SOURCE_DATE_EPOCH empty" unchanged 22:13 "$out"

for bad in 1700000000.5 soon; do
    if out=$(build SOURCE_DATE_EPOCH=$bad); then
        printf '%s\n' "$out" >&2; fail "SOURCE_DATE_EPOCH=$bad did not stop the build"
    fi
    case $out in
        *"SOURCE_DATE_EPOCH is $bad"*) echo "source-date: SOURCE_DATE_EPOCH=$bad stops the build" ;;
        *) printf '%s\n' "$out" >&2
            fail "SOURCE_DATE_EPOCH=$bad stopped the build without naming it" ;;
    esac
done
echo "source-date: a build takes SOURCE_DATE_EPOCH for the current time, and no stamp is later"
