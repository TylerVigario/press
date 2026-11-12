#!/bin/sh
# just-mod.sh — press.just lists its recipes as the README says: under `mod press`, `just press`
# lists press's, and under `import`, `just --list` lists them beside the repository's own.
#
#   sh .github/just-mod.sh
#
# Run by CI on press's just and on the oldest press.just accepts. A scratch repository holds the
# kit under third_party/press, as the installer puts it, with no justfile of press's own, and a
# justfile with a recipe of its own beside press's. A second just started bare finds the justfile
# of the directory it runs in, the repository's, so `just press` must not list `mine`.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "just-mod: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$tmp/repo
mkdir -p "$repo/third_party/press"
cp -R lib.typ lib press.toml template calibration.typ fonts tools press.just "$repo/third_party/press/"
cd "$repo"

printf 'mod press "third_party/press/press.just"\nmine:\n    echo mine\n' > justfile
out=$(just press 2>&1) || { printf '%s\n' "$out" >&2; fail "under mod, just press failed"; }
case $out in *"build doc"*) ;; *) fail "under mod, just press does not list press's recipes: $out" ;; esac
case $out in *mine*) fail "under mod, just press lists the repository's own recipes: $out" ;; esac

printf "import 'third_party/press/press.just'\nmine:\n    echo mine\n" > justfile
out=$(just --list 2>&1) || { printf '%s\n' "$out" >&2; fail "under import, just --list failed"; }
case $out in *"build doc"*) ;; *) fail "under import, just --list does not list press's recipes: $out" ;; esac
echo "just-mod: just press lists press's recipes under mod, and just --list under import"
