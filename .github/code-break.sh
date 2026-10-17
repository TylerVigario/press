#!/bin/sh
# code-break.sh — under a template, a code block a document lets break does break, and one it
# does not moves whole.
#
#   sh .github/code-break.sh
#
# Run by CI's audit job and the oldest-toolchain job, which have poppler. brief and base box
# every code block with code(), unbreakable; a document lets one break with its own rule,
# `it => code(it, breakable: true)`, as parts.typ shows. .github/code-break.typ has a block that
# opts in and one that does not, each too long for the space left on its page. The first must
# start on the page it reaches, its lines split across the turn, and the second must start on a
# page of its own, its first line and its last on the same page.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "code-break: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/code-break.typ "$tmp/probe.pdf"
pages=$(pdfinfo "$tmp/probe.pdf" | sed -n 's/^Pages: *//p')
# page_of <line>: the page a code line prints on.
page_of() {
    p=1
    while [ "$p" -le "$pages" ]; do
        pdftotext -f "$p" -l "$p" "$tmp/probe.pdf" - | grep -qx "$1" && { echo "$p"; return; }
        p=$((p + 1))
    done
    fail "\"$1\" is on no page"
}
[ "$(page_of 'echo opted 0')" != "$(page_of 'echo opted 59')" ] \
    || fail "the block that opts in to breaking did not break across a page"
[ "$(page_of 'echo whole 0')" = "$(page_of 'echo whole 59')" ] \
    || fail "the block that does not opt in broke across a page"
echo "code-break: a block a document lets break breaks, and one it does not moves whole"
