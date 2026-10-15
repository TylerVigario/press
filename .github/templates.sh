#!/bin/sh
# templates.sh — every package version in the tree compiles its own template, against itself.
#
#   sh .github/templates.sh
#
# Run by CI's two build jobs, at the pinned typst and at the oldest press accepts.
#
# A package version is compiled only where a document imports it, and press's own
# documents import one version. Without this, a new version directory could merge, and be
# released, without anything ever building it.
#
# A version also names itself in three places: its typst.toml, its template's import, and
# the usage line at the top of lib.typ. The release copies a directory to make a tooling-only
# version, and a copy that misses one of them scaffolds documents importing the version
# before it. So every `@<namespace>/press:<version>` in lib.typ and the template must name
# the directory it sits in.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "templates: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

n=0
for dir in packages/*/press/*/; do
    dir=${dir%/}
    [ -f "$dir/typst.toml" ] || continue
    ns=${dir#packages/}
    ns=${ns%%/*}
    v=${dir##*/}
    self="@$ns/press:$v"

    manifest=$(sed -n 's/^version *= *"\(.*\)"$/\1/p' "$dir/typst.toml")
    [ "$manifest" = "$v" ] || fail "$dir/typst.toml says version ${manifest:-nothing}, not $v"

    others=$(grep -ho '@[a-z0-9-]*/press:[0-9][0-9.]*[0-9]' "$dir/lib.typ" "$dir/template/main.typ" \
               | { grep -vx "$self" || true; } | sort -u)
    [ -z "$others" ] || fail "$dir names another version than $self: $(printf '%s' "$others" | tr '\n' ' ')"
    grep -q "^#import \"$self\"" "$dir/template/main.typ" \
        || fail "$dir/template/main.typ does not import $self"

    # typst exits 0 on a warning, so a template that warns is caught by reading its output.
    out=$(typst compile --package-path packages --font-path fonts --ignore-system-fonts \
            "$dir/template/main.typ" "$tmp/$ns-$v.pdf" 2>&1) \
        || { printf '%s\n' "$out" >&2; fail "$self: the template does not compile"; }
    if printf '%s\n' "$out" | grep -q '^warning:'; then
        printf '%s\n' "$out" >&2
        fail "$self: the template compiles with warnings"
    fi
    echo "$self: the template compiles against itself"
    n=$((n + 1))
done
[ "$n" -gt 0 ] || fail "no package version found under packages/*/press/"
