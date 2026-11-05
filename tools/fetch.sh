#!/bin/sh
# fetch.sh — download a file, trying again on a timeout or a 5xx, and say how each try went.
#
#   sh third_party/press/tools/fetch.sh <url> <file>
#
# install-typst.sh downloads typst with it, and press's CI its tools. A download from GitHub's
# releases takes two hops: github.com answers with a redirect, and its asset host serves the file.
# A failure prints only its status, which names neither hop, so a slow redirect and a slow file
# look the same. This says, for each try, the host that answered each hop, its status, and the
# IDs it gave the request (github.com's request ID and edge region, the asset host's caches); then
# how long the last try's hops took. Said on stderr, after the download, whether it worked or not.
set -eu

[ $# -eq 2 ] && [ -n "$1" ] && [ -n "$2" ] || { echo "usage: sh fetch.sh <url> <file>" >&2; exit 2; }
url=$1 out=$2
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --fail so an HTML error page is an error rather than an archive that fails to extract with a
# message about its format. --retry so a timeout or a 500, 502, 503 or 504 is tried again before
# it fails, after waits of 1, 2, 4, 8 and 16 seconds. --dump-header keeps every response of every
# try; --write-out times the last.
rc=0
times=$(curl --fail --silent --show-error --location --retry 5 --dump-header "$tmp/headers" \
    --write-out '%{time_redirect} %{time_starttransfer} %{time_total}' --output "$out" "$url") || rc=$?

echo "fetch: ${url##*/}" >&2
# A try is its responses up to the first that is not a redirect; each response's host is the one
# the response before it in the try pointed to, or the URL's own.
[ -s "$tmp/headers" ] && awk -v first="$(printf '%s' "$url" | sed 's|^[a-z]*://||; s|[/:?].*||')" '
    function value(v) { v = $0; sub(/^[^:]*:[ \t]*/, "", v); return v }
    function hop(ids) {
        ids = (id != "" ? "request " id : "") (region != "" ? ", " region : "")
        if (served != "") ids = served (cache != "" ? "; " cache : "")
        line = line (line != "" ? " -> " : "") host " " status (ids != "" ? " [" ids "]" : "")
        id = region = served = cache = ""
    }
    { sub(/\r$/, "") }
    /^HTTP\// {
        if (status != "") hop()
        if (status !~ /^3/ && line != "") { printf "fetch:   try %d: %s\n", ++n, line; line = "" }
        host = (status ~ /^3/ && to != "") ? to : first
        status = $2; to = ""
        next
    }
    { name = tolower($0); sub(/:.*/, "", name) }
    name == "location" { to = value(); if (to ~ /^\//) to = host; else { sub(/^[a-z]*:\/\//, "", to); sub(/[\/:?].*/, "", to) } }
    name == "x-github-request-id" { id = value() }
    name == "x-github-edge-region" { region = value() }
    name == "x-served-by" { served = value() }
    name == "x-cache" { cache = value() }
    END { if (status != "") hop(); if (line != "") printf "fetch:   try %d: %s\n", ++n, line }
' "$tmp/headers" >&2
[ -n "$times" ] && printf '%s\n' "$times" | awk '{
    printf "fetch:   the last try: %s%.2fs to its first byte, %.2fs in all\n",
        ($1 > 0 ? sprintf("redirects %.2fs, ", $1) : ""), $2, $3 }' >&2
exit "$rc"
