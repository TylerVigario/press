#!/bin/sh
# install-check.sh — the installers install, update and refuse as their headers say, and leave
# nothing behind.
#
#   sh .github/install-check.sh <dir holding what .github/bundle.sh built>
#
# Run by CI on every pull request. Serves the bundle from 127.0.0.1 and runs each installer the
# way the README's line does, piped from the server, with PRESS_BASE_URL pointing it there: the
# path tested is the released one but for the address. install.sh runs twice, once with only
# curl and once with only wget beside the tools its header names, so it needs no more than
# those; install.ps1 runs through pwsh, when there is one (CI's runner has it). Each one:
#
#   · into an empty directory: press/ is the archive's, and nothing else is left;
#   · over an older copy holding a file this release lacks: that file is gone;
#   · over the same release: the same press/;
#   · from an archive that is not the one released, or an address with nothing there: refused,
#     the old copy untouched;
#   · over a press/ that is not a kit, a press/ that is a git checkout, or from inside press/:
#     refused, untouched;
#   · as the installer's source, with no release written in: refused.
set -eu

b=$(cd "${1:?usage: sh .github/install-check.sh <bundle dir>}" && pwd)
fail() { echo "install-check: $*" >&2; exit 1; }
tmp=$(mktemp -d)
server=
trap 'if [ -n "$server" ]; then kill "$server" 2>/dev/null || true; fi; rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
here=$(cd "$(dirname "$0")/.." && pwd)
version=$(sed -n 's/^version *= *"\(.*\)"$/\1/p' "$here/press.toml")

# good/ is the bundle; bad/ holds other bytes under the archives' names.
mkdir -p "$tmp/serve/good" "$tmp/serve/bad" "$tmp/ref"
cp "$b/press.tar.gz" "$b/press.zip" "$b/install.sh" "$b/install.ps1" "$tmp/serve/good/"
echo 'not the release' > "$tmp/serve/bad/press.tar.gz"
echo 'not the release' > "$tmp/serve/bad/press.zip"
(cd "$tmp/ref" && tar -xzf "$b/press.tar.gz")

python3 -u -m http.server 0 --bind 127.0.0.1 --directory "$tmp/serve" > "$tmp/server.log" 2>&1 &
server=$!
port=
i=0
while [ -z "$port" ]; do
    i=$((i + 1))
    [ "$i" -le 50 ] || { cat "$tmp/server.log" >&2; fail "the test server did not start"; }
    sleep 0.1
    port=$(sed -n 's/.* port \([0-9][0-9]*\).*/\1/p' "$tmp/server.log")
done
url="http://127.0.0.1:$port"

# A PATH holding only the tools install.sh's header names, with one downloader.
sh=$(command -v sh)
for get in curl wget; do
    mkdir -p "$tmp/bin-$get"
    for c in sh "$get" sha256sum mktemp tar gzip sed mv rm; do
        p=$(command -v "$c") || fail "this check needs $c"
        ln -s "$p" "$tmp/bin-$get/$c"
    done
done

kinds="curl wget"
if command -v pwsh >/dev/null 2>&1; then kinds="$kinds pwsh"
else echo "install-check: no pwsh here, so install.ps1 is not run"; fi

# run <kind> <dir> [<base>]: runs the installer in <dir> as its README line does, fetching the
# archive from <base> (good/ by default); its output is in $tmp/out.
run() {
    base=${3:-$url/good}
    case $1 in
        curl) (cd "$2" && PATH="$tmp/bin-curl" PRESS_BASE_URL="$base" \
                   "$sh" -c "curl -fsSL '$url/good/install.sh' | sh") ;;
        wget) (cd "$2" && PATH="$tmp/bin-wget" PRESS_BASE_URL="$base" \
                   "$sh" -c "wget -qO- '$url/good/install.sh' | sh") ;;
        pwsh) (cd "$2" && PRESS_BASE_URL="$base" \
                   pwsh -NoProfile -NonInteractive -Command "irm '$url/good/install.ps1' | iex") ;;
    esac > "$tmp/out" 2>&1
}
ok() {  # ok <kind> <case> <expected line>
    grep -qF "$3" "$tmp/out" || { cat "$tmp/out" >&2; fail "$1, $2: no \"$3\""; }
}
refused() {  # refused <kind> <case> <expected words>
    grep -qF "$3" "$tmp/out" || { cat "$tmp/out" >&2; fail "$1, $2: refused, but without \"$3\""; }
}
entries() { (cd "$1" && find . -mindepth 1 -maxdepth 1 | sed 's#^\./##' | LC_ALL=C sort | tr '\n' ' '); }
only_press() {  # only_press <kind> <case> <dir>: press/ and nothing else, and it is the release's
    [ "$(entries "$3")" = "press " ] || fail "$1, $2: left $(entries "$3")"
    diff -r "$tmp/ref/press" "$3/press" >/dev/null || fail "$1, $2: press/ is not the release's"
}
untouched() {  # untouched <kind> <case> <dir> <copy>: <dir> is exactly <copy>
    diff -r "$4" "$3" >/dev/null || fail "$1, $2: changed what it refused"
}

for k in $kinds; do
    d="$tmp/$k"

    mkdir -p "$d/fresh"
    run "$k" "$d/fresh" || { cat "$tmp/out" >&2; fail "$k, fresh: failed"; }
    ok "$k" fresh "press: installed $version in "
    only_press "$k" fresh "$d/fresh"

    mkdir -p "$d/older"
    cp -R "$tmp/ref/press" "$d/older/"
    sed 's/^version *= *".*"$/version = "0.0.1"/' "$tmp/ref/press/press.toml" > "$d/older/press/press.toml"
    echo 'removed by a later release' > "$d/older/press/tools/gone.sh"
    run "$k" "$d/older" || { cat "$tmp/out" >&2; fail "$k, older: failed"; }
    ok "$k" older ", replacing 0.0.1"
    only_press "$k" older "$d/older"

    run "$k" "$d/older" || { cat "$tmp/out" >&2; fail "$k, same: failed"; }
    ok "$k" same "press: reinstalled $version in "
    only_press "$k" same "$d/older"

    for c in bad missing; do
        mkdir -p "$d/$c"
        cp -R "$tmp/ref/press" "$d/$c/"
        echo 'kept' > "$d/$c/press/mine"
        cp -R "$d/$c" "$d/$c.before"
        if [ "$c" = bad ]; then base=$url/bad words="is not the archive press $version was released with"
        else base=$url/nothing words="could not download $url/nothing/press."; fi
        ! run "$k" "$d/$c" "$base" || fail "$k, $c: succeeded"
        refused "$k" "$c" "$words"
        untouched "$k" "$c" "$d/$c" "$d/$c.before"
    done

    mkdir -p "$d/notkit/press" "$d/checkout/press" "$d/inside"
    echo 'not press' > "$d/notkit/press/notes"
    echo 'gitdir: ../.git/modules/press' > "$d/checkout/press/.git"
    cp -R "$tmp/ref/press" "$d/inside/"
    for c in notkit:"is not a press kit" checkout:"is a git checkout" inside:"press's own directory"; do
        dir=$d/${c%%:*}
        [ "${c%%:*}" != inside ] || dir=$d/inside/press
        cp -R "$dir" "$dir.before"
        ! run "$k" "$dir" || fail "$k, ${c%%:*}: succeeded"
        refused "$k" "${c%%:*}" "${c#*:}"
        untouched "$k" "${c%%:*}" "$dir" "$dir.before"
    done
done

# The installers as they sit in the tree, unstamped.
mkdir -p "$tmp/source"
! (cd "$tmp/source" && sh "$here/install.sh") > "$tmp/out" 2>&1 || fail "install.sh's source ran"
refused sh source "no release written in"
if command -v pwsh >/dev/null 2>&1; then
    ! (cd "$tmp/source" && pwsh -NoProfile -NonInteractive -Command \
        "Get-Content -Raw '$here/install.ps1' | iex") > "$tmp/out" 2>&1 || fail "install.ps1's source ran"
    refused ps1 source "no release written in"
fi
[ -z "$(entries "$tmp/source")" ] || fail "an unstamped installer left files"

echo "install-check: the installers install, update and refuse as they should ($kinds)"
