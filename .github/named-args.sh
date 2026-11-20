#!/bin/sh
# named-args.sh — a part that takes any number of items stops the build on an argument given by
# name that it does not take, naming it, where it took the argument and printed nothing of it.
#
#   sh .github/named-args.sh
#
# Run by CI on press's typst and on the oldest toolchain. .github/named-args.typ gives each of
# letterhead, re, enclosures, units, sheet, steps, flow, src and sources an argument named
# `extra`, and letterhead `contact` and `phone`, as letter() names them: each compile must fail
# with the part's name and the argument's. Given only what they take, all nine must compile.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "named-args: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# compile <part>: the document with that part's call; prints typst's errors.
compile() {
    typst compile --root . --font-path fonts --ignore-system-fonts --input "part=$1" \
        .github/named-args.typ "$tmp/$1.pdf" 2>&1
}

out=$(compile none) \
    || { printf '%s\n' "$out" >&2; fail "the nine parts, given what they take, do not compile"; }
for part in letterhead re enclosures units sheet steps flow src sources; do
    if out=$(compile "$part"); then fail "$part() given an argument named extra compiles"; fi
    case $out in
        *"$part() takes no argument named \"extra\""*) echo "named-args: $part() stops on extra" ;;
        *) printf '%s\n' "$out" >&2; fail "$part() given extra stops without naming it" ;;
    esac
done
if out=$(compile letterhead-two); then
    fail "letterhead() given contact and phone by name compiles"
fi
case $out in
    *'letterhead() takes no argument named "contact" or "phone"'*) ;;
    *) printf '%s\n' "$out" >&2
        fail "letterhead() given contact and phone stops without naming both" ;;
esac
echo "named-args: a part that takes any number of items stops on an argument given by name"
