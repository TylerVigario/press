#!/bin/sh
# stamps.sh — an unchanged page keeps its stamp where its PDF is gone, from .press-stamps, which
# the repository commits, and a changed one is stamped anew.
#
#   sh .github/stamps.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. A scratch repository
# holds a copy of the kit under third_party/press and two briefs, one of them setting its own
# date, built with build.sh in UTC at SOURCE_DATE_EPOCH's times:
#
#   · new at 1700000000, 22:13:20, each with a line in .press-stamps under its heading line;
#   · in a copy with its PDF and no .press-stamps, as a press before it left it, unchanged at
#     22:13:20, and listed;
#   · after clean.sh, with no build record, unchanged at 22:13:20 though built at 23:13:20;
#   · in a copy of the repository's committed files, at another path, unchanged at 22:13:20;
#   · in that copy, edited and not built, changed at 23:13: the checksum tells the edit;
#   · the dated one, with its PDF there and no build record, unchanged at 22:13:20, though its
#     PDF's own date is the document's;
#   · with an older .press-stamps put back over a page edited since, unchanged at that page's
#     own stamp, and its line written again, and never cached while its line is not the record's;
#   · a document deleted, its line gone at the next build;
#   · a PDF outside the root given no line;
#   · a line that is not one, or a PDF listed twice, stopping the build with its line number.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "stamps: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$tmp/repo
mkdir -p "$repo/third_party/press" "$repo/docs"
cp -R lib.typ lib press.toml template calibration.typ fonts tools "$repo/third_party/press/"
# note <repo> <text>: the brief whose words change.
note() {
    printf '#import "/third_party/press/lib.typ": *\n%s\n\n%s\n' \
        '#show: brief.with(title: [Note], author: "Sam Example")' "$2" > "$1/docs/note.typ"
}
note "$repo" "One line."
printf '#set document(date: datetime(year: 2026, month: 1, day: 1))\n%s\n%s\n\n%s\n' \
    '#import "/third_party/press/lib.typ": *' \
    '#show: brief.with(title: [Rack power], author: "Sam Example")' \
    'The rack draws 2.4 kW.' > "$repo/docs/dated.typ"

# build <repo> <time> <doc>...: build in UTC at that SOURCE_DATE_EPOCH; prints build.sh's lines.
build() {
    r=$1 t=$2
    shift 2
    (cd "$r" && env PRESS_TZ=UTC SOURCE_DATE_EPOCH="$t" sh third_party/press/tools/build.sh "$@" 2>&1)
}
# expect <what> <doc> <status> <time> <build's lines>
expect() {
    case $5 in
        *"$2.pdf: $3, "*"updated $4 UTC"*) echo "stamps: $1: $3, $4" ;;
        *) printf '%s\n' "$5" >&2; fail "$1: $2 is not $3 at $4 UTC" ;;
    esac
}
# line <repo> <doc>: the document's line in .press-stamps.
line() { grep "^docs/$2\.typ	" "$1/.press-stamps" || true; }
tab=$(printf '\t')

out=$(build "$repo" 1700000000 docs/note.typ docs/dated.typ) \
    || { printf '%s\n' "$out" >&2; fail "the first build failed"; }
expect "a new page" note new "2023-11-14 22:13:20" "$out"
expect "a new page that sets its own date" dated new "2023-11-14 22:13:20" "$out"
[ "$(head -n 1 "$repo/.press-stamps")" = \
    "# press's stamps: when each document's page last changed, kept by its build. Commit this file." ] \
    || fail ".press-stamps does not begin with the line saying what it is"
sum=$(sha256sum "$repo/print/docs/note.pdf" | cut -d ' ' -f 1)
[ "$(line "$repo" note)" = \
    "docs/note.typ${tab}print/docs/note.pdf${tab}2023-11-14T22:13:20Z${tab}$sum" ] \
    || { cat "$repo/.press-stamps" >&2; fail "the new page's line is not its document, PDF, stamp and checksum"; }
echo "stamps: each new page has its line"

# A press without .press-stamps built this page, in a copy with its PDF: the PDF's own stamp
# keeps its time.
before=$tmp/before
cp -R "$repo" "$before"
rm -f "$before/.press-stamps" "$before/third_party/press/.build-record"
out=$(build "$before" 1700003600 docs/note.typ) \
    || { printf '%s\n' "$out" >&2; fail "the build with no .press-stamps failed"; }
expect "built before .press-stamps" note unchanged "2023-11-14 22:13:20" "$out"
[ "$(line "$before" note)" = \
    "docs/note.typ${tab}print/docs/note.pdf${tab}2023-11-14T22:13:20Z${tab}$sum" ] \
    || { cat "$before/.press-stamps" >&2; fail "the page built before .press-stamps was not listed"; }
echo "stamps: and is listed at its stamp"

(cd "$repo" && sh third_party/press/tools/clean.sh)
rm -f "$repo/third_party/press/.build-record"
out=$(build "$repo" 1700003600 docs/note.typ docs/dated.typ) \
    || { printf '%s\n' "$out" >&2; fail "the build after clean.sh failed"; }
expect "after clean.sh" note unchanged "2023-11-14 22:13:20" "$out"
expect "after clean.sh, the page that sets its own date" dated unchanged "2023-11-14 22:13:20" "$out"

# The repository's committed files, at another path: no print/, and the kit's .gitignore keeps
# the build record out.
copy=$tmp/copy
mkdir -p "$copy/third_party/press"
cp -R "$repo/docs" "$repo/.press-stamps" "$copy/"
cp -R lib.typ lib press.toml template calibration.typ fonts tools "$copy/third_party/press/"
out=$(build "$copy" 1700003600 docs/note.typ docs/dated.typ) \
    || { printf '%s\n' "$out" >&2; fail "the build of the copy failed"; }
expect "in a copy" note unchanged "2023-11-14 22:13:20" "$out"
expect "in a copy, the page that sets its own date" dated unchanged "2023-11-14 22:13:20" "$out"

rm -rf "$copy/print" "$copy/third_party/press/.build-record"
note "$copy" "Two lines."
out=$(build "$copy" 1700003600 docs/note.typ) \
    || { printf '%s\n' "$out" >&2; fail "the build of the edited copy failed"; }
expect "in a copy, edited and not built" note changed "2023-11-14 23:13:20" "$out"

rm -f "$repo/third_party/press/.build-record"
out=$(build "$repo" 1700003600 docs/dated.typ) \
    || { printf '%s\n' "$out" >&2; fail "the build of the dated page with no record failed"; }
expect "with its PDF and no build record, the page that sets its own date" dated unchanged \
    "2023-11-14 22:13:20" "$out"

# A line another build overwrote, or a branch's older file: the PDF's own stamp keeps the page's.
cp "$repo/.press-stamps" "$tmp/older"
note "$repo" "Two lines."
out=$(build "$repo" 1700003600 docs/note.typ) \
    || { printf '%s\n' "$out" >&2; fail "the edited build failed"; }
expect "edited" note changed "2023-11-14 23:13:20" "$out"
cp "$tmp/older" "$repo/.press-stamps"
out=$(build "$repo" 1700007200 docs/note.typ) \
    || { printf '%s\n' "$out" >&2; fail "the build under the older .press-stamps failed"; }
expect "under an older .press-stamps" note unchanged "2023-11-14 23:13:20" "$out"
case $(line "$repo" note) in
    *"${tab}2023-11-14T23:13:20Z${tab}"*) echo "stamps: its line is written again" ;;
    *) cat "$repo/.press-stamps" >&2; fail "the page's line was not written again at 23:13:20" ;;
esac
out=$(build "$repo" 1700007200 docs/note.typ) || { printf '%s\n' "$out" >&2; fail "the rebuild failed"; }
expect "built again" note cached "2023-11-14 23:13:20" "$out"
cp "$tmp/older" "$repo/.press-stamps"
out=$(build "$repo" 1700007200 docs/note.typ) \
    || { printf '%s\n' "$out" >&2; fail "the build under the older .press-stamps, with a record, failed"; }
expect "with a build record, under an older .press-stamps" note unchanged "2023-11-14 23:13:20" "$out"

rm "$repo/docs/dated.typ"
out=$(build "$repo" 1700007200 docs/note.typ) || { printf '%s\n' "$out" >&2; fail "the build failed"; }
[ -z "$(line "$repo" dated)" ] || { cat "$repo/.press-stamps" >&2; fail "a deleted document keeps its line"; }
echo "stamps: a deleted document's line goes"

(cd "$repo" && env PRESS_TZ=UTC sh third_party/press/tools/stamp.sh docs/note.typ "$tmp/out.pdf" \
    --root . --font-path third_party/press/fonts --ignore-system-fonts >/dev/null 2>&1) \
    || fail "the build to a PDF outside the root failed"
! grep -qF "$tmp/out.pdf" "$repo/.press-stamps" || fail "a PDF outside the root has a line"
echo "stamps: a PDF outside the root has no line"

cp "$repo/.press-stamps" "$tmp/good"
printf '<<<<<<< HEAD\n' >> "$repo/.press-stamps"
if out=$(build "$repo" 1700007200 docs/note.typ); then printf '%s\n' "$out" >&2; fail "a line that is not one did not stop the build"; fi
case $out in
    *".press-stamps, line 3: "*) echo "stamps: a line that is not one stops the build" ;;
    *) printf '%s\n' "$out" >&2; fail "a line that is not one stopped the build without its number" ;;
esac
cp "$tmp/good" "$repo/.press-stamps"
line "$repo" note > "$tmp/twice"
cat "$tmp/twice" >> "$repo/.press-stamps"
if out=$(build "$repo" 1700007200 docs/note.typ); then printf '%s\n' "$out" >&2; fail "a PDF listed twice did not stop the build"; fi
case $out in
    *".press-stamps, line 3: lists print/docs/note.pdf twice"*) echo "stamps: a PDF listed twice stops the build" ;;
    *) printf '%s\n' "$out" >&2; fail "a PDF listed twice stopped the build without saying so" ;;
esac
echo "stamps: an unchanged page keeps its stamp from .press-stamps, and a changed one is stamped anew"
