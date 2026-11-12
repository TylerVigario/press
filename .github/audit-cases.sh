#!/bin/sh
# audit-cases.sh — the audit passes what it should and refuses what it should.
#
#   sh .github/audit-cases.sh
#
# Run by CI on press's typst and on the oldest toolchain. Each file in .github/audit-cases/ is a
# document with one known answer: a pass-*.typ must audit clean, and a fail-*.typ must be refused
# with the words its `// expect:` line gives. A pass case is a false finding the audit once made,
# kept so it is not made again; a fail case is a fault a pass exists to catch, kept so a fix for the
# first does not blind it. Then the build, stamp.sh, audits as check does: it fails a fail case with
# its PDF written, and without poppler it says the audit was skipped and succeeds. And: a pass that
# cannot run fails the audit whatever the document accepts; open items and estimates are counted,
# with the audit's tools or without them; a line of code that wraps fails the build without them
# too; a title still to be named is counted once, however many pages print it, or none, and a
# footer's status once; with no XML parser, or no python, check refuses and a build skips the
# passes that need one, unrecorded; and an unchanged document is not compiled again.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "audit-cases: $*" >&2; exit 1; }
tmp=$(mktemp -d)
scan=.github/audit-cases/scan/scan.pdf
trap 'rm -rf "$tmp"; rm -f "$scan"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

flags="--root . --font-path fonts --ignore-system-fonts"
# The stand-in scan the scan cases place, in typst's own Libertinus, a face press does not vendor.
typst compile --root . --ignore-system-fonts .github/audit-cases/scan/scan.typ "$scan"
for f in .github/audit-cases/*.typ; do
    c=$(basename "$f" .typ)
    # shellcheck disable=SC2086  # $flags is a list of flags
    if sh tools/check.sh "$f" "$tmp/$c.pdf" . $flags > "$tmp/out" 2>&1; then clean=yes; else clean=no; fi
    case $c in
        pass-*) [ "$clean" = yes ] || { cat "$tmp/out" >&2; fail "$c was refused"; }
                echo "audit-cases: $c audits clean" ;;
        fail-*) want=$(sed -n 's#^// expect: ##p' "$f")
                [ -n "$want" ] || fail "$c has no // expect: line"
                [ "$clean" = no ] || fail "$c audited clean"
                grep -qF "$want" "$tmp/out" || { cat "$tmp/out" >&2; fail "$c was refused, but not for \"$want\""; }
                echo "audit-cases: $c is refused: $want" ;;
        *) fail "$c is named neither pass-* nor fail-*" ;;
    esac
done

# shellcheck disable=SC2086
sh tools/stamp.sh .github/audit-cases/pass-marker-beside-word.typ "$tmp/b/pass.pdf" $flags > "$tmp/out" 2>&1 \
    || { cat "$tmp/out" >&2; fail "the build failed a pass case"; }
# shellcheck disable=SC2086
! sh tools/stamp.sh .github/audit-cases/fail-text-on-text.typ "$tmp/b/fail.pdf" $flags > "$tmp/out" 2>&1 \
    || fail "the build passed a fail case"
grep -qF "prints text on text" "$tmp/out" || { cat "$tmp/out" >&2; fail "the build failed a fail case, but not for its finding"; }
[ -f "$tmp/b/fail.pdf" ] || fail "the build that failed its audit left no PDF"
# shellcheck disable=SC2086
PRESS_PDFTOTEXT=/nonexistent/pdftotext sh tools/stamp.sh .github/audit-cases/fail-text-on-text.typ "$tmp/b/fail.pdf" $flags \
    > "$tmp/out" 2>&1 || { cat "$tmp/out" >&2; fail "a build without poppler failed"; }
grep -qF "is not audited: " "$tmp/out" || { cat "$tmp/out" >&2; fail "a build without poppler did not say it was not audited"; }
echo "audit-cases: the build audits as check does, and without poppler says it did not"

# A pass that cannot run is never a finding, so no acceptance covers it: with pdftoppm missing,
# the case that accepts its ink finding is refused, and nothing is said to be accepted.
# shellcheck disable=SC2086
! PRESS_PDFTOPPM=/nonexistent/pdftoppm sh tools/check.sh .github/audit-cases/pass-finding-accepted.typ \
    "$tmp/b/accepted.pdf" . $flags > "$tmp/out" 2>&1 || fail "a pass that could not run was accepted"
! grep -qF "accepted" "$tmp/out" || { cat "$tmp/out" >&2; fail "a pass that could not run was called accepted"; }
echo "audit-cases: a pass that cannot run fails the audit, whatever the document accepts"

# The line-overlap check reads each glyph from pdftocairo: without it, check fails, naming the
# variable that names it, and a build skips the pass and says so.
slanted=.github/audit-cases/pass-slanted-lines.typ
# shellcheck disable=SC2086
! PRESS_PDFTOCAIRO=/nonexistent/pdftocairo sh tools/check.sh "$slanted" "$tmp/b/cairo.pdf" . \
    $flags > "$tmp/out" 2>&1 || fail "check passed without pdftocairo"
grep -qF "set PRESS_PDFTOCAIRO" "$tmp/out" \
    || { cat "$tmp/out" >&2; fail "check without pdftocairo did not name PRESS_PDFTOCAIRO"; }
# shellcheck disable=SC2086
PRESS_PDFTOCAIRO=/nonexistent/pdftocairo sh tools/stamp.sh "$slanted" "$tmp/b/cairo.pdf" $flags \
    > "$tmp/out" 2>&1 || { cat "$tmp/out" >&2; fail "a build without pdftocairo failed"; }
grep -qF "skipping the line-overlap check (no pdftocairo" "$tmp/out" \
    || { cat "$tmp/out" >&2; fail "a build without pdftocairo did not say it skipped the pass"; }
echo "audit-cases: without pdftocairo, check fails naming it, and a build skips the pass"

# Nor is a Python that cannot parse the passes: it exits 1, as CPython does for a script whose
# syntax is newer than itself. The stand-in answers the probe, `-c pass`, and fails any script.
op=$tmp/old-python
printf '#!/bin/sh
[ "$1" = -c ] && [ "$2" = pass ] && exit 0
echo "SyntaxError: invalid syntax" >&2; exit 1
' \
    > "$op"
chmod +x "$op"
# shellcheck disable=SC2086
! PRESS_PYTHON=$op sh tools/check.sh .github/audit-cases/pass-finding-accepted.typ \
    "$tmp/b/old.pdf" . $flags > "$tmp/out" 2>&1 || fail "a Python that could not parse the passes was accepted"
! grep -qF "accepted" "$tmp/out" || { cat "$tmp/out" >&2; fail "a pass Python could not parse was called accepted"; }
for c in "the printable-area check" "the line-overlap check"; do
    grep -qF "press: $c could not run: $op exited 1" "$tmp/out" \
        || { cat "$tmp/out" >&2; fail "$c did not say it could not run"; }
done
echo "audit-cases: a Python that cannot parse the passes fails the audit, whatever the document accepts"

# Open items and estimates are counted, not failed: the pass case above audited clean, and says
# how many of each.
# shellcheck disable=SC2086
sh tools/check.sh .github/audit-cases/pass-unsourced.typ "$tmp/o/open.pdf" . $flags > "$tmp/out" 2>&1 \
    || { cat "$tmp/out" >&2; fail "a document with open items and an estimate failed its audit"; }
grep -qF "has 2 open items" "$tmp/out" || { cat "$tmp/out" >&2; fail "the audit did not count the open items"; }
grep -qF "prints 1 estimate," "$tmp/out" || { cat "$tmp/out" >&2; fail "the audit did not count the estimate"; }
echo "audit-cases: open items and estimates are counted, a missing value and an empty box are not, and none fails the audit"

# Counting them needs only typst, so a build without the audit's tools still counts them.
# shellcheck disable=SC2086
PRESS_PDFTOTEXT=/nonexistent/pdftotext sh tools/stamp.sh .github/audit-cases/pass-unsourced.typ "$tmp/b/open.pdf" $flags \
    > "$tmp/out" 2>&1 || { cat "$tmp/out" >&2; fail "a build with open items and without poppler failed"; }
grep -qF "has 2 open items" "$tmp/out" || { cat "$tmp/out" >&2; fail "a build without poppler did not count the open items"; }
grep -qF "prints 1 estimate," "$tmp/out" || { cat "$tmp/out" >&2; fail "a build without poppler did not count the estimate"; }
echo "audit-cases: a build without the audit's tools still counts the open items and estimates"

# A line of code that wraps is found from press's marks, which need only typst, so a build
# without the audit's tools still fails it, as it fails the measuring grid.
for v in PRESS_PDFTOTEXT=/nonexistent/pdftotext PRESS_PDFFONTS=/nonexistent/pdffonts; do
    t=${v##*/}
    # shellcheck disable=SC2086
    ! env "$v" sh tools/stamp.sh \
        .github/audit-cases/fail-code-wrap.typ "$tmp/b/wrap.pdf" $flags > "$tmp/out" 2>&1 \
        || fail "a build without $t passed a line of code that wraps"
    grep -qF "is too long for it and wraps" "$tmp/out" \
        || { cat "$tmp/out" >&2; fail "a build without $t failed, but not for the line that wraps"; }
    grep -qF "is not audited: " "$tmp/out" || { cat "$tmp/out" >&2; fail "a build without $t did not say it was not audited"; }
done
echo "audit-cases: a build without the audit's tools still fails a line of code that wraps"

# A title still to be named is one open item, though the footer prints it on every page: counted
# once where a header prints it too, once where a head of the document's own prints it with
# title(), and once where only the footer does, from a later page where the first has none, or
# beside a title() with its own words. A letter and a résumé print it nowhere, and count it once.
for c in pass-unsourced-title pass-unsourced-title-own-head pass-unsourced-title-footer \
    pass-unsourced-title-cover pass-unsourced-title-own-text pass-unsourced-title-letter \
    pass-unsourced-title-resume; do
    # shellcheck disable=SC2086
    sh tools/check.sh ".github/audit-cases/$c.typ" "$tmp/o/$c.pdf" . $flags > "$tmp/out" 2>&1 \
        || { cat "$tmp/out" >&2; fail "$c failed its audit"; }
    grep -qF "has 1 open item " "$tmp/out" \
        || { cat "$tmp/out" >&2; fail "$c did not count its title once"; }
done
echo "audit-cases: a title still to be named is counted once, however many pages print it, or none"
# A footer's status still to be settled is one open item too, though every page from the first with
# a footer prints it.
# shellcheck disable=SC2086
sh tools/check.sh .github/audit-cases/pass-unsourced-status.typ "$tmp/o/status.pdf" . $flags > "$tmp/out" 2>&1 \
    || { cat "$tmp/out" >&2; fail "pass-unsourced-status failed its audit"; }
grep -qF "has 1 open item " "$tmp/out" \
    || { cat "$tmp/out" >&2; fail "pass-unsourced-status did not count its status once"; }
echo "audit-cases: a footer's status still to be settled is counted once, however many pages print it"

# A python with no XML parser cannot run the text-on-text pass. A stand-in python, the real one
# with expat taken away at startup, is named by PRESS_PYTHON: check fails, and says why, and a
# build says it skipped the pass and is not recorded as audited.
nx=$tmp/no-xml
mkdir -p "$nx"
printf 'import sys\nsys.modules["pyexpat"] = None\nsys.modules["xml.parsers.expat"] = None\n' > "$nx/sitecustomize.py"
py=$(command -v python3)
printf '#!/bin/sh\nPYTHONPATH="%s" exec "%s" "$@"\n' "$nx" "$py" > "$nx/python"
chmod +x "$nx/python"
# shellcheck disable=SC2086
! PRESS_PYTHON=$nx/python sh tools/check.sh .github/audit-cases/pass-marker-beside-word.typ \
    "$tmp/x/check.pdf" . $flags > "$tmp/out" 2>&1 || { cat "$tmp/out" >&2; fail "check passed with no XML parser"; }
grep -qF "needs a python with an XML parser" "$tmp/out" \
    || { cat "$tmp/out" >&2; fail "check failed with no XML parser, but did not say why"; }
# shellcheck disable=SC2086
PRESS_PYTHON=$nx/python sh tools/stamp.sh .github/audit-cases/pass-marker-beside-word.typ "$tmp/x/build.pdf" $flags \
    > "$tmp/out" 2>&1 || { cat "$tmp/out" >&2; fail "a build with no XML parser failed"; }
grep -qF "skipping the line-overlap check" "$tmp/out" \
    || { cat "$tmp/out" >&2; fail "a build with no XML parser did not say it skipped the pass"; }
! grep -qF "== .github/audit-cases/pass-marker-beside-word.typ	$tmp/x/build.pdf" .build-record 2>/dev/null \
    || fail "a build that skipped a pass was recorded as audited"
echo "audit-cases: with no XML parser, check fails and a build skips the pass, unrecorded"

# With no python at all, check refuses, as it does without poppler, and a build skips the two
# passes that need one, says so and is not recorded as audited. The PATH they run with is one
# directory linking every program on PATH but python.
np=$tmp/no-python
mkdir -p "$np"
printf '%s\n' "$PATH" | tr ':' '\n' | while IFS= read -r d; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
        # An empty directory leaves the pattern itself, which names nothing.
        [ -e "$f" ] || continue
        n=${f##*/}
        case $n in python*) continue ;; esac
        [ -e "$np/$n" ] || ln -s "$f" "$np/$n"
    done
done
if (PATH=$np; command -v python3 || command -v python) >/dev/null 2>&1; then
    fail "the PATH with no python has one"
fi
# shellcheck disable=SC2086
! PATH=$np PRESS_PYTHON='' sh tools/check.sh .github/audit-cases/pass-marker-beside-word.typ \
    "$tmp/np/check.pdf" . $flags > "$tmp/out" 2>&1 || { cat "$tmp/out" >&2; fail "check passed with no python"; }
grep -qF "check needs a python" "$tmp/out" \
    || { cat "$tmp/out" >&2; fail "check failed with no python, but did not say why"; }
# shellcheck disable=SC2086
PATH=$np PRESS_PYTHON='' sh tools/stamp.sh .github/audit-cases/pass-marker-beside-word.typ "$tmp/np/build.pdf" \
    $flags > "$tmp/out" 2>&1 || { cat "$tmp/out" >&2; fail "a build with no python failed"; }
grep -qF "skipping the printable-area check (no working python found)" "$tmp/out" \
    && grep -qF "skipping the line-overlap check (no working python found)" "$tmp/out" \
    || { cat "$tmp/out" >&2; fail "a build with no python did not say it skipped both passes"; }
! grep -qF "== .github/audit-cases/pass-marker-beside-word.typ	$tmp/np/build.pdf" .build-record 2>/dev/null \
    || fail "a build that skipped its passes was recorded as audited"
echo "audit-cases: with no python, check refuses and a build skips its two passes, unrecorded"

# The build record: a document whose inputs are unchanged is not compiled again, and an edit
# to it is. typst runs through a wrapper that notes each compile.
r=$tmp/record
mkdir -p "$r/bin" "$r/kit"
cp -R lib.typ lib press.toml fonts tools "$r/kit/"
printf '#!/bin/sh\n[ "$1" != compile ] || echo compile >> "%s/compiles"\nexec "%s" "$@"\n' "$r" "$(command -v typst)" > "$r/bin/typst"
chmod +x "$r/bin/typst"
printf '#import "/kit/lib.typ": *\n#set document(title: [Record], author: "press")\n#set page(..card)\n#set text(font: face-text)\nOne line.\n' > "$r/doc.typ"
build() { (cd "$r" && PATH="$r/bin:$PATH" sh kit/tools/stamp.sh doc.typ print/doc.pdf --root . --font-path kit/fonts --ignore-system-fonts 2>/dev/null); }
build > /dev/null || fail "the record case did not build"
grep -q "^== doc.typ" "$r/kit/.build-record" 2>/dev/null || fail "a build that passed its audit left no record"
: > "$r/compiles"
case $(build) in cached*) ;; *) fail "an unchanged document did not build as cached" ;; esac
[ ! -s "$r/compiles" ] || fail "an unchanged document was compiled again"
echo 'Another line.' >> "$r/doc.typ"
case $(build) in changed*) ;; *) fail "an edited document did not build as changed" ;; esac
[ -s "$r/compiles" ] || fail "an edited document was not compiled"
echo "audit-cases: an unchanged document is not compiled again, and an edited one is"
