#!/bin/sh
# audit-cases.sh — the audit passes what it should and refuses what it should.
#
#   sh .github/audit-cases.sh
#
# Run by CI's audit job. Each file in .github/audit-cases/ is a document with one known answer:
# a pass-*.typ must audit clean, and a fail-*.typ must be refused with the words its
# `// expect:` line gives. A pass case is a false finding the audit once made, kept so it is not
# made again; a fail case is a fault a pass exists to catch, kept so a fix for the first does not
# blind it.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "audit-cases: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

flags="--root . --font-path fonts --ignore-system-fonts"
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
