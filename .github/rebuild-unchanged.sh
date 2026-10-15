#!/bin/sh
# rebuild-unchanged.sh — a second build of an unchanged document reports it unchanged.
#
#   sh .github/rebuild-unchanged.sh <document>...
#
# Run by CI's two build jobs, after a first build. An unchanged page keeps its stamp: build
# reads the old one back from the PDF. A second build must therefore report each document
# unchanged, and a stamp it cannot read back re-stamps the page and shows here.
#
# Each document's own report line must say unchanged. A run that printed no line for one
# fails too, rather than passing for want of anything to object to.
#
# Its build record goes first: with it, an unchanged document is not compiled at all, and this
# is the proof that compiling it again at its stamp gives the same bytes.
set -eu
[ $# -gt 0 ] || { echo "::error::rebuild-unchanged.sh needs at least one document"; exit 1; }
bad=0
for doc in "$@"; do
    rm -f .build-record
    out=$(just build "$doc")
    printf '%s\n' "$out"
    case $out in
        *": unchanged, "*) ;;
        *) echo "::error::a rebuild of the unchanged $doc did not report it unchanged"; bad=1 ;;
    esac
done
exit "$bad"
