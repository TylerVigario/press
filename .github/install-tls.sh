#!/bin/sh
# install-tls.sh — install.ps1 leaves the TLS setting of the PowerShell that ran it as it was.
#
#   sh .github/install-tls.sh <dir holding what .github/bundle.sh built>
#
# Run by CI on every pull request, through pwsh. The setting is the process's, so a run with
# irm | iex in someone's own session would keep whatever the installer set. Serves the bundle
# from 127.0.0.1 and runs install.ps1 as the README's line does, piped from the server, but in
# one session that sets the setting first and reads it once the installer has ended:
#
#   · SystemDefault, which leaves the choice to the system, and TLS 1.3 alone: left as they are,
#     and nothing said of them;
#   · TLS 1.0 alone, which offers no TLS 1.2: TLS 1.2 added for the download, a line saying so,
#     and the setting as it was once the installer ends, installed or refused for an address
#     with nothing there.
set -eu

b=$(cd "${1:?usage: sh .github/install-tls.sh <bundle dir>}" && pwd)
fail() { echo "install-tls: $*" >&2; exit 1; }
command -v pwsh >/dev/null 2>&1 || fail "this check needs pwsh"
tmp=$(mktemp -d)
server=
trap 'if [ -n "$server" ]; then kill "$server" 2>/dev/null || true; fi; rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
here=$(cd "$(dirname "$0")/.." && pwd)
version=$(sed -n 's/^version *= *"\(.*\)"$/\1/p' "$here/press.toml")

mkdir -p "$tmp/serve"
cp "$b/press.zip" "$b/install.ps1" "$tmp/serve/"
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

# run <case> <setting> <base>: in a fresh directory, one session sets <setting>, runs the
# installer, says how it ended, and prints the setting after; its output is in $tmp/out.
run() {
    mkdir "$tmp/$1"
    (cd "$tmp/$1" && PRESS_BASE_URL="$3" pwsh -NoProfile -NonInteractive -Command "
        [Net.ServicePointManager]::SecurityProtocol = '$2'
        try { irm '$url/install.ps1' | iex; 'ended: installed' } catch { 'ended: refused, ' + \$_ }
        'after: ' + [Net.ServicePointManager]::SecurityProtocol") > "$tmp/out" 2>&1 \
        || { cat "$tmp/out" >&2; fail "$1: the session failed"; }
}
has() {  # has <case> <line>
    grep -qxF "$2" "$tmp/out" || { cat "$tmp/out" >&2; fail "$1: no line \"$2\""; }
}
says() {  # says <case> <words>
    grep -qF "$2" "$tmp/out" || { cat "$tmp/out" >&2; fail "$1: no \"$2\""; }
}

for c in SystemDefault:system Tls13:tls13; do
    run "${c#*:}" "${c%%:*}" "$url"
    has "${c#*:}" "ended: installed"
    has "${c#*:}" "after: ${c%%:*}"
    ! grep -qF "TLS setting" "$tmp/out" || { cat "$tmp/out" >&2; fail "${c#*:}: spoke of the TLS setting"; }
done

run tls10 Tls "$url"
has tls10 "ended: installed"
says tls10 "press: installed $version in "
has tls10 "press: this PowerShell's TLS setting, Tls, offers no TLS 1.2, which GitHub needs; adding it for the download"
has tls10 "press: this PowerShell's TLS setting is Tls again"
has tls10 "after: Tls"

run tls10-missing Tls "$url/nothing"
says tls10-missing "ended: refused, press: could not download $url/nothing/press.zip"
has tls10-missing "press: this PowerShell's TLS setting, Tls, offers no TLS 1.2, which GitHub needs; adding it for the download"
has tls10-missing "press: this PowerShell's TLS setting is Tls again"
has tls10-missing "after: Tls"

echo "install-tls: install.ps1 leaves the session's TLS setting as it was (SystemDefault, Tls13 and Tls)"
