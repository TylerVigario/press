#!/bin/sh
# templates.sh — the template compiles where it stands, and as a document new.sh scaffolds.
#
#   sh .github/templates.sh
#
# Run by CI's two build jobs, at the pinned typst and at the oldest press accepts.
#
# Two compiles, because the template lives two lives. In press's tree it imports press
# relatively, ../lib.typ, so it compiles in place. A repo gets it through tools/new.sh, which
# copies it with that import rewritten to press's path from the project root. So the second
# compile is a scratch repo holding a copy of the kit at vendor/press, scaffolded by new.sh
# exactly as a downstream repo would be. Either failing, or warning, fails the run: typst
# exits 0 on a warning, so warnings are read from its output.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "templates: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

compile() {   # <root> <font dir> <document> <what>
    out=$(cd "$1" && typst compile --root . --font-path "$2" --ignore-system-fonts "$3" "$tmp/out.pdf" 2>&1) \
        || { printf '%s\n' "$out" >&2; fail "$4 does not compile"; }
    if printf '%s\n' "$out" | grep -q '^warning:'; then
        printf '%s\n' "$out" >&2
        fail "$4 compiles with warnings"
    fi
    echo "$4 compiles"
}

compile . fonts template/main.typ "the template, in place,"

repo="$tmp/repo"
mkdir -p "$repo/vendor/press"
cp -R lib.typ press.toml template fonts tools "$repo/vendor/press/"
(cd "$repo" && sh vendor/press/tools/new.sh docs/scaffolded >/dev/null)
grep -q '^#import "/vendor/press/lib.typ": \*' "$repo/docs/scaffolded/main.typ" \
    || fail "new.sh did not point the copy's import at /vendor/press/lib.typ"
compile "$repo" vendor/press/fonts docs/scaffolded/main.typ "the template, scaffolded by new.sh,"
