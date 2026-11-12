#!/bin/sh
# contexts.sh — every CI job is a required context, by a name GitHub keeps whole.
#
#   sh .github/contexts.sh
#
# Run by CI. Each job of .github/workflows/ci.yml is a required context of its own, by its name:
# .github/rulesets/main.json requires each one, and the title check. A job added without its context
# covers less while protection reads as complete, and a context left with no job holds every pull
# request. GitHub cuts a check's name past 100 characters, to 97 and "...", so a longer one never
# arrives under the name required. The jobs' names and the title check's must be exactly the
# contexts main.json requires, each 100 characters or fewer. awk counts bytes where its locale does,
# so a name holding é is held to a little less, never more.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "contexts: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# A job's id is the line indented two spaces under `jobs:`, a comment after it or not, and its
# name the line indented four under it, as every job in ci.yml writes them. A job with no name
# reports under its id, and one given a matrix under its name and the matrix's values, as
# "Tests (ubuntu-latest, 64)": no context main.json requires is either, so the first fails
# unrequired and the second holds every pull request for a check that never arrives.
awk '
    function done() {
        if (job != "" && !named) print "a job with no name, which reports under its id: " job
        job = ""
    }
    /^jobs:/ { in_jobs = 1; next }
    in_jobs && /^[^ #]/ { done(); in_jobs = 0 }
    in_jobs && /^  [A-Za-z0-9_-]+:[ \t]*(#.*)?$/ {
        done(); job = $1; sub(/:$/, "", job); named = 0; strategy = 0; next
    }
    job == "" { next }
    /^    name: / { named = 1 }
    /^    [^ #]/ { strategy = /^    strategy:/ }
    strategy && /^      matrix:/ {
        print "a job given a matrix, which reports under its name and the matrix values: " job
    }
    END { done() }
' .github/workflows/ci.yml > "$tmp/odd"
[ ! -s "$tmp/odd" ] || { sed 's/^/contexts: /' "$tmp/odd" >&2; exit 1; }
sed -n 's/^    name: //p' .github/workflows/ci.yml | sed "s/^'\(.*\)'\$/\1/; s/''/'/g" > "$tmp/jobs"
grep -qx '    name: Validate PR title' .github/workflows/commit-convention.yml ||
    fail "commit-convention.yml has no job named Validate PR title"
echo 'Validate PR title' >> "$tmp/jobs"
sort "$tmp/jobs" > "$tmp/have"
jq -r '.rules[] | select(.type == "required_status_checks")
    | .parameters.required_status_checks[].context' .github/rulesets/main.json | sort > "$tmp/want"
[ -s "$tmp/want" ] || fail "main.json requires no context"
if ! cmp -s "$tmp/have" "$tmp/want"; then
    comm -23 "$tmp/have" "$tmp/want" | sed 's/^/contexts: a job main.json does not require: /' >&2
    comm -13 "$tmp/have" "$tmp/want" | sed 's/^/contexts: required, and no job has the name: /' >&2
    exit 1
fi
long=$(awk 'length > 100' "$tmp/have")
[ -z "$long" ] || fail "GitHub cuts these past 100 characters, and the context never arrives: $long"
echo "contexts: all $(wc -l < "$tmp/have" | tr -d ' ') checks are required, each by a name GitHub keeps whole"
