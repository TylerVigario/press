#!/bin/sh
# timeouts.sh — every job in press's workflows stops at a timeout of its own.
#
#   sh .github/timeouts.sh
#
# Run by CI. A job without timeout-minutes runs until GitHub cancels it at six hours, so a step
# that hangs holds a runner, and the pull request waiting on it, until someone notices. A job is
# the line indented two spaces under `jobs:`, as every workflow here writes one; it must set
# timeout-minutes, indented four, unless it calls another workflow with `uses:`, whose own jobs
# carry theirs and where GitHub refuses one.
set -eu
cd "$(dirname "$0")/.."

missing=$(awk '
    function done() { if (job != "" && !timed) print file ": " job; job = ""; timed = 0 }
    FNR == 1 { done(); in_jobs = 0 }
    /^jobs:/ { in_jobs = 1; next }
    in_jobs && /^[^ #]/ { done(); in_jobs = 0 }
    in_jobs && /^  [A-Za-z0-9_-]+:[ \t]*$/ { done(); job = $1; sub(/:$/, "", job); file = FILENAME; next }
    in_jobs && /^    (timeout-minutes|uses):/ { timed = 1 }
    END { done() }
' .github/workflows/*.yml)
[ -z "$missing" ] || { echo "timeouts: these jobs set no timeout-minutes:" >&2; printf '%s\n' "$missing" >&2; exit 1; }
echo "timeouts: every job in $(ls .github/workflows/*.yml | wc -l | tr -d ' ') workflows stops at a timeout of its own"
