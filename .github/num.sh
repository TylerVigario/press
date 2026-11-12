#!/bin/sh
# num.sh — num() groups a number's whole part by thousands, from four digits, and leaves its
# decimals and its sign as typst prints them.
#
#   sh .github/num.sh
#
# Run by CI on press's typst and on the oldest toolchain, with poppler. .github/num.typ prints
# one number to a line, and each line must read as below; the minus is typst's, U+2212. Its
# page 2 sets a figure grouped by spaces at the end of a line in 144 paragraphs, and each must
# be whole on one line, as a line broken inside it reads as two numbers.
set -eu
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

typst compile --root . --font-path fonts --ignore-system-fonts .github/num.typ "$tmp/probe.pdf"
pdftotext -l 1 "$tmp/probe.pdf" - | sed '/^[[:space:]]*$/d' > "$tmp/got"
cat > "$tmp/want" <<'WANT'
999
1,000
3,465
12,480
1,234,567
−3,465
1,234.5
1,234,567.50
−1,000.10
1 234 567
WANT
diff "$tmp/want" "$tmp/got" >&2 || { echo "num: num() printed the lines marked > above" >&2; exit 1; }
whole=$(pdftotext -f 2 -l 2 "$tmp/probe.pdf" - | grep -cE '(^|[^0-9])1[^0-9]+234[^0-9]+567($|[^0-9])') \
    || true
[ "$whole" -eq 144 ] || {
    echo "num: $((144 - whole)) of 144 figures grouped by spaces were broken across two lines" >&2
    exit 1
}
echo "num: num() groups by thousands, keeps the decimals and the sign, and keeps a figure whole"
