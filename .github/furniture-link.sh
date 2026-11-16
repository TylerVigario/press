#!/bin/sh
# furniture-link.sh — a link in a page's header or footer prints its address after it.
#
#   sh .github/furniture-link.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. typst sets no footnote
# from a page's header or footer and prints only its number, so link-note's footnote there put
# a number on every page that noted nothing, and the body's footnotes skipped one a page.
# .github/furniture-link.typ sets a link in brief's footer(status:), in a header a letter is
# given, and in the footer of a page no template sets, its margins typst's own, each over two
# pages: on both, the link must print its address in parentheses after its text, with no number,
# and the body's links must be footnoted 1 and 2.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "furniture-link: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# lines <case> <page>: the page's lines that hold text.
lines() { pdftotext -layout -f "$2" -l "$2" "$tmp/$1.pdf" - | grep -v '^[[:space:]]*$'; }

for c in brief:bottom:'status page (example.org/status)' \
         letter:top:'letters (example.org/letters)' \
         plain:bottom:'home (example.org/home)'; do
    case=${c%%:*} rest=${c#*:}
    where=${rest%%:*} want=${rest#*:}
    typst compile --root . --font-path fonts --ignore-system-fonts --input "case=$case" \
        .github/furniture-link.typ "$tmp/$case.pdf"
    pages=$(pdfinfo "$tmp/$case.pdf" | sed -n 's/^Pages: *//p')
    [ "$pages" -eq 2 ] || fail "$case: $pages pages, not 2"
    for p in 1 2; do
        if [ "$where" = top ]; then line=$(lines "$case" "$p" | head -1)
        else line=$(lines "$case" "$p" | tail -1); fi
        printf '%s\n' "$line" | grep -qF "$want" \
            || fail "$case, page $p: its $where line has no \"$want\": $line"
        # A digit straight after the link's text, or after its address, is a footnote's number.
        link=${want%% (*}
        for d in 0 1 2 3 4 5 6 7 8 9; do
            ! printf '%s\n' "$line" | grep -qF -e "$link$d" -e "$want$d" \
                || fail "$case, page $p: the link in its $where line carries a footnote number: $line"
        done
    done
    for n in 1:one 2:two; do
        p=${n%%:*} word=${n#*:}
        lines "$case" "$p" | grep -qF "cites $word$p." \
            || fail "$case, page $p: the body's link is not footnoted $p: $(lines "$case" "$p" | tr '\n' '|')"
        lines "$case" "$p" | grep -qE "^[[:space:]]*${p}example\.org/$word\$" \
            || fail "$case, page $p: no footnote $p, example.org/$word: $(lines "$case" "$p" | tr '\n' '|')"
    done
done
echo "furniture-link: a link in a page's header or footer prints its address after it, and the body's footnotes count on"
