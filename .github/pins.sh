#!/bin/sh
# pins.sh — compare each tool CI installs at a hand-pinned version with its latest release.
#
#   sh .github/pins.sh            print the comparison
#   sh .github/pins.sh --issues   and keep an issue open for each release a pin is behind
#
# The Pins workflow runs it weekly with --issues. Run by hand without it, it changes nothing.
#
# These are the pins Dependabot cannot see: a version assigned in a shell script or an env:
# block, or named on an npx command line, declares no dependency for it to match. They stay
# pinned by version and digest; this only says when upstream has moved. A tool pinned by
# hand anywhere else needs a line at the bottom.
#
# Needs gh (authenticated: GH_TOKEN in a workflow), curl and jq. A pin it cannot read, or a
# release it cannot fetch, fails the run: a tool left out would read as one that is current.
set -eu
cd "$(dirname "$0")/.."

issues=false
case ${1:-} in
    --issues) issues=true ;;
    "") ;;
    *) echo "usage: sh .github/pins.sh [--issues]" >&2; exit 2 ;;
esac

fail() { echo "pins: $*" >&2; exit 1; }

# Digits and dots, starting with a digit. Anything else, including the two lines of a
# pattern that matched twice, is not a version this can compare.
version() {
    case $1 in
        [0-9]*) case $1 in *[!0-9.]*) return 1 ;; esac ;;
        *) return 1 ;;
    esac
}

# The title names the release, so an issue closed by hand stays closed until a later
# release opens the next one.
suffix=" is released, and CI still pins an earlier version"
if $issues; then
    all=$(gh issue list --state all --limit 1000 --json number,title,state,body)
fi

report() {
    title="$tool $latest$suffix"
    # This tool's issues, whichever release they name.
    mine=$(printf '%s' "$all" | jq -c --arg p "$tool " --arg s "$suffix" '[.[]
        | select((.title | startswith($p)) and (.title | endswith($s)))
        | select(.title | ltrimstr($p) | rtrimstr($s) | test("^[0-9][0-9.]*$"))]')

    if [ "$state" = current ]; then
        for n in $(printf '%s' "$mine" | jq -r '.[] | select(.state == "OPEN") | .number'); do
            gh issue close "$n" --comment "CI now pins $tool $pinned, its latest release."
            echo "  closed #$n"
        done
        return 0
    fi

    body=$(printf 'CI installs %s %s, pinned in `%s`. Its latest release is %s:\n%s\n\n%s\n%s\n' \
        "$tool" "$pinned" "$file" "$latest" "$url" \
        "Dependabot cannot see this pin, so nothing else reports it. Opened by the Pins" \
        "workflow, which keeps these numbers current and closes this once the pin catches up.")
    same=$(printf '%s' "$mine" | jq -c --arg t "$title" '[.[] | select(.title == $t)][0] // empty')
    if [ -z "$same" ]; then
        n=$(gh issue create --title "$title" --body "$body")
        n=${n##*/}
        echo "  opened #$n"
    else
        n=$(printf '%s' "$same" | jq -r .number)
        if [ "$(printf '%s' "$same" | jq -r .state)" = OPEN ] \
                && [ "$(printf '%s' "$same" | jq -r .body)" != "$body" ]; then
            gh issue edit "$n" --body "$body" > /dev/null
            echo "  updated #$n"
        fi
    fi
    # An open issue for an earlier release is answered by this one.
    for old in $(printf '%s' "$mine" \
            | jq -r --arg t "$title" '.[] | select(.state == "OPEN" and .title != $t) | .number'); do
        gh issue close "$old" --comment "Superseded by #$n."
        echo "  closed #$old"
    done
}

# check <tool> <file> <sed program printing its pin> <gh:owner/repo | npm:package>
check() {
    tool=$1 file=$2
    pinned=$(sed -n "$3" "$file")
    version "$pinned" || fail "cannot read one $tool version from $file"
    case $4 in
        gh:*)  r=$(gh api "repos/${4#gh:}/releases/latest" --jq '.tag_name + " " + .html_url')
               latest=${r%% *} url=${r#* }
               latest=${latest#v} ;;
        npm:*) latest=$(curl -fsSL "https://registry.npmjs.org/${4#npm:}/latest" | jq -r .version)
               url="https://www.npmjs.com/package/${4#npm:}/v/$latest" ;;
        *)     fail "unknown source for $tool: $4" ;;
    esac
    version "$latest" || fail "cannot read the latest $tool release"
    if [ "$(printf '%s\n%s\n' "$pinned" "$latest" | sort -V | tail -n 1)" = "$pinned" ]; then
        state=current
    else
        state=behind
    fi
    printf '%-18s %-9s %-9s %s\n' "$tool" "$pinned" "$latest" "$state"
    if $issues; then report; fi
}

printf '%-18s %-9s %s\n' tool pinned latest
check typst .github/actions/typst-toolchain/action.yml 's/^ *TYPST_VERSION=//p' gh:typst/typst
check just .github/actions/typst-toolchain/action.yml 's/^ *JUST_VERSION=//p' gh:casey/just
check cocogitto .github/setup-cog.sh 's/^COG_VERSION=//p' gh:cocogitto/cocogitto
check actionlint .github/workflows/ci.yml \
    's/^ *ACTIONLINT_VERSION: *"\([^"]*\)"$/\1/p' gh:rhysd/actionlint
check markdownlint-cli2 .github/workflows/ci.yml \
    's/.*npx --yes markdownlint-cli2@\([^ ]*\).*/\1/p' npm:markdownlint-cli2
