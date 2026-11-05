#!/bin/sh
# fetch-tries.sh — tools/fetch.sh tries a failed download again, and says how each try went.
#
#   sh .github/fetch-tries.sh
#
# Run by CI, with Python. A server on the loopback answers as GitHub's releases do, a redirect and
# then the file, but its file host times out twice before it serves. fetch.sh must try three
# times, say each try's hops, their hosts, statuses and IDs, and leave the file as served. A
# missing file is not tried again: its 404 is said, and curl's exit status is fetch.sh's.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "fetch-tries: $*" >&2; exit 1; }
tmp=$(mktemp -d)
pid=
trap '[ -z "$pid" ] || kill "$pid" 2>/dev/null; rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

cat > "$tmp/server.py" <<'EOF'
import http.server, sys
tries = 0
class Handler(http.server.BaseHTTPRequestHandler):
    def answer(self, status, headers, body=b""):
        self.send_response(status)
        for k, v in headers.items():
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        global tries
        if self.path == "/release":
            self.answer(302, {"Location": "/asset?sig=1", "X-GitHub-Request-Id": "R1"})
        elif self.path.startswith("/asset"):
            tries += 1
            if tries < 3:
                self.answer(504, {"X-Served-By": "edge-a, edge-b", "X-Cache": "MISS, MISS"})
            else:
                self.answer(200, {"X-Served-By": "edge-a, edge-b", "X-Cache": "MISS, HIT"}, b"the file\n")
        else:
            self.answer(404, {})
    def log_message(self, *args):
        pass
server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
with open(sys.argv[1], "w") as f:
    f.write(str(server.server_port))
server.serve_forever()
EOF
python3 -I "$tmp/server.py" "$tmp/port" &
pid=$!
i=0
until [ -s "$tmp/port" ]; do
    i=$((i + 1))
    [ "$i" -le 50 ] || fail "the server did not start"
    sleep 0.1
done
base="http://127.0.0.1:$(cat "$tmp/port")"

sh tools/fetch.sh "$base/release" "$tmp/file" 2> "$tmp/said" || fail "a download that worked on its third try failed: $(cat "$tmp/said")"
[ "$(cat "$tmp/file")" = "the file" ] || fail "the file is not as served"
for line in \
    "fetch:   try 1: 127.0.0.1 302 [request R1] -> 127.0.0.1 504 [edge-a, edge-b; MISS, MISS]" \
    "fetch:   try 2: 127.0.0.1 302 [request R1] -> 127.0.0.1 504 [edge-a, edge-b; MISS, MISS]" \
    "fetch:   try 3: 127.0.0.1 302 [request R1] -> 127.0.0.1 200 [edge-a, edge-b; MISS, HIT]"; do
    grep -qxF "$line" "$tmp/said" || fail "it did not say \"$line\"; it said: $(cat "$tmp/said")"
done
grep -q '^fetch:   the last try: redirects [0-9.]*s, [0-9.]*s to its first byte, [0-9.]*s in all$' "$tmp/said" ||
    fail "it did not time the last try; it said: $(cat "$tmp/said")"

rc=0
sh tools/fetch.sh "$base/missing" "$tmp/missing" 2> "$tmp/said" || rc=$?
[ "$rc" = 22 ] || fail "a 404 exits $rc, not curl's 22"
grep -qxF "fetch:   try 1: 127.0.0.1 404" "$tmp/said" || fail "it did not say the 404; it said: $(cat "$tmp/said")"
! grep -q 'try 2' "$tmp/said" || fail "a 404 was tried again"
echo "fetch-tries: a failed download is tried again, each try's hops are said, and curl's status is kept"
