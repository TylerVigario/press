#!/bin/sh
# signature-page.sh — signature() keeps the paragraph before it on its page, under every template.
#
#   sh .github/signature-page.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/signature-page.typ
# sets 36 letters, each on pages of its own and each a paragraph longer than the one before, so
# that in some the last paragraph ends too near a page's foot for the signature. Under each of
# press's five templates, the page each letter is signed on must hold its last paragraph:
# signature() once moved to the next page alone, with none of the letter's text. One letter or
# more must also carry its last paragraph onto a page the paragraph before it is not on, or the
# check no longer sets a signature where a page breaks.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "signature-page: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for t in base brief letter recipe resume; do
    typst compile --root . --font-path fonts --ignore-system-fonts --input template="$t" \
        .github/signature-page.typ "$tmp/$t.pdf"
    pdftotext -layout "$tmp/$t.pdf" "$tmp/$t.txt"
    # Each page is a record. The pages that letter K is signed on, ends on, and holds its next to
    # last paragraph on are read from their leads; a letter signed away from its last paragraph is
    # printed, and the count of letters whose last paragraph was carried over is printed last.
    awk -v n=36 '
        BEGIN { RS = "\f" }
        function seen(pat, skip, arr,    s, k) {
            s = $0
            while (match(s, pat)) {
                k = substr(s, RSTART + skip, RLENGTH - skip)
                sub(/[^0-9].*/, "", k)
                arr[k] = NR
                s = substr(s, RSTART + RLENGTH)
            }
        }
        {
            seen("Signer [0-9]+", 7, signed)
            seen("Case [0-9]+ ends", 5, ends)
            s = $0
            while (match(s, "Case [0-9]+, paragraph [0-9]+")) {
                c = substr(s, RSTART + 5, RLENGTH - 5)
                k = c; sub(/,.*/, "", k)
                i = c; sub(/.* /, "", i)
                para[k, i] = NR
                s = substr(s, RSTART + RLENGTH)
            }
        }
        END {
            carried = 0
            for (k = 1; k <= n; k++) {
                if (!(k in signed) || !(k in ends)) { print "letter " k " is missing"; continue }
                if (signed[k] != ends[k])
                    print "letter " k " is signed on page " signed[k] ", its last paragraph on page " ends[k]
                if (k > 1 && para[k, k - 1] != ends[k]) carried++
            }
            print "carried " carried
        }' "$tmp/$t.txt" > "$tmp/$t.out"
    if grep -v '^carried ' "$tmp/$t.out" > "$tmp/$t.bad"; then
        fail "under $t, a signature is on a page without the paragraph before it:" \
            "$(cat "$tmp/$t.bad")"
    fi
    [ "$(sed -n 's/^carried //p' "$tmp/$t.out")" -gt 0 ] \
        || fail "under $t, no letter's last paragraph went onto a page the one before it is not on;" \
            "the check no longer sets a signature where a page breaks"
done
echo "signature-page: under every template, a signature keeps the paragraph before it on its page"
