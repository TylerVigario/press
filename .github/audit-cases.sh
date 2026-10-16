#!/bin/sh
# audit-cases.sh — the audit passes what it should and refuses what it should.
#
#   sh .github/audit-cases.sh
#
# Run by CI's audit job. Each file in .github/audit-cases/ is a document with one known answer:
# a pass-*.typ must audit clean, and a fail-*.typ must be refused with the words its
# `// expect:` line gives. A pass case is a false finding the audit once made, kept so it is not
# made again; a fail case is a fault a pass exists to catch, kept so a fix for the first does not
# blind it. Then the build, stamp.sh, audits as check does: it fails a fail case with its PDF
# written, and without poppler it says the audit was skipped and succeeds.
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
case $(build) in unchanged*) ;; *) fail "an unchanged document did not build as unchanged" ;; esac
[ ! -s "$r/compiles" ] || fail "an unchanged document was compiled again"
echo 'Another line.' >> "$r/doc.typ"
case $(build) in changed*) ;; *) fail "an edited document did not build as changed" ;; esac
[ -s "$r/compiles" ] || fail "an edited document was not compiled"
echo "audit-cases: an unchanged document is not compiled again, and an edited one is"
