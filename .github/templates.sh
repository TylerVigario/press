#!/bin/sh
# templates.sh — each template compiles where it stands, and as a document new.sh scaffolds.
#
#   sh .github/templates.sh
#
# Run by CI's two build jobs, at the pinned typst and at the oldest press accepts.
#
# Two compiles of each, because a template lives two lives. In press's tree it imports press
# relatively, ../lib.typ, so it compiles in place. A repo gets it through tools/new.sh, which
# copies it with that import rewritten to press's path from the project root. So the second
# compile is a scratch repo holding a copy of the kit, scaffolded by new.sh exactly as a
# downstream repo would be. Not at the README's third_party/press, which bundle-check.sh
# installs to: press works wherever it sits under the root, so this copy sits deeper, under a
# name with a space in it. Either failing, or warning, fails the run: typst
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

repo="$tmp/repo"
kit="assets/typst kit/press"
mkdir -p "$repo/$kit"
cp -R lib.typ press.toml template fonts tools "$repo/$kit/"
for f in template/*.typ; do
    t=$(basename "$f" .typ)
    compile . fonts "$f" "template/$t.typ, in place,"
    (cd "$repo" && sh "$kit/tools/new.sh" "docs/$t" "$t" >/dev/null)
    grep -qxF "#import \"/$kit/lib.typ\": *" "$repo/docs/$t/main.typ" \
        || fail "new.sh did not point $t's copy's import at /$kit/lib.typ"
    compile "$repo" "$kit/fonts" "docs/$t/main.typ" "template/$t.typ, scaffolded by new.sh,"
done
