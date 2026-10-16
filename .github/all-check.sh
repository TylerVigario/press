#!/bin/sh
# all-check.sh — `just all` builds a repository's documents: not their parts, and not press's own
# files.
#
#   sh .github/all-check.sh
#
# Run by CI's two build jobs, which have just. A scratch repository holds a copy of the kit under
# third_party/press, as the README installs it, and imports press.just; its docs/ holds a
# document, a book (main.typ beside a chapter) and a shared part (_shared.typ). `just all .`
# reaches press's folder too, and must build the document and the book and nothing else: a
# library file built on its own fails its audit, and a starter or the calibration sheet is not
# the repository's document.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "all-check: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$tmp/repo
mkdir -p "$repo/third_party/press" "$repo/docs/book"
cp -R lib.typ lib press.toml template calibration.typ fonts tools press.just "$repo/third_party/press/"
printf 'import "third_party/press/press.just"\n' > "$repo/justfile"
printf '#import "/third_party/press/lib.typ": *\n#set text(font: face-text)\nOne line.\n' > "$repo/docs/note.typ"
cp "$repo/docs/note.typ" "$repo/docs/book/main.typ"
cp "$repo/docs/note.typ" "$repo/docs/_shared.typ"
printf 'A chapter, built only as part of its book.\n' > "$repo/docs/book/chapter.typ"

out=$(cd "$repo" && just all . 2>&1) || { printf '%s\n' "$out" >&2; fail "just all . failed"; }
built=$(cd "$repo" && find print -name '*.pdf' | LC_ALL=C sort | tr '\n' ' ')
[ "$built" = "print/docs/book/main.pdf print/docs/note.pdf " ] \
    || { printf '%s\n' "$out" >&2; fail "just all . built $built"; }
echo "all-check: just all . builds the documents, not their parts or press's files"
