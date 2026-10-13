#!/bin/sh
# write-changelog.sh — regenerate CHANGELOG.md at a release, keeping its hand-written
# first release.
#
# Run by the release workflow, with the new tag set on HEAD in the runner's clone:
#
#   sh .github/write-changelog.sh [CHANGELOG.md]
#
# Between the FIRST and the LAST `- - -` line the file is cog's full `cog changelog`,
# rewritten at every release. The preamble above the first separator and everything from
# the last one on are kept verbatim. Below the last is the first release, written by hand
# as "Initial release.": a first release has no earlier version to differ from, but cog
# renders it as every commit since the repository began, compared from the first commit
# (cocogitto/cocogitto#580). cog's own section for that version is dropped.
#
# The same method as greenroom-win's ci/write-changelog.ps1. Both go when #580 is fixed.
#
# COG_CHANGELOG names a file to read cog's output from instead of running cog, so the
# joining can be tested without a repository.
set -eu

path=${1:-CHANGELOG.md}
gen=$(mktemp)
out=$(mktemp)
trap 'rm -f "$gen" "$out"' EXIT

if [ -n "${COG_CHANGELOG:-}" ]; then
    cp "$COG_CHANGELOG" "$gen"
else
    cog changelog > "$gen"
fi

awk -v gen="$gen" -v path="$path" '
    function fail(msg) { print "write-changelog: " msg > "/dev/stderr"; exit 1 }
    { line[++n] = $0; if ($0 == "- - -") { if (!first) first = n; last = n } }
    END {
        if (!first || first == last)
            fail(path " needs a \"- - -\" line under its preamble and one above the hand-written first release")
        for (i = last; i <= n; i++)
            if (line[i] ~ /^## [0-9]+\.[0-9]+\.[0-9]+[ \t]*$/) { v = substr(line[i], 4); sub(/[ \t]+$/, "", v); break }
        if (v == "") fail("no \"## X.Y.Z\" heading below the last separator of " path)

        # cog sections, up to the one for the hand-written version.
        while ((getline g < gen) > 0) {
            if (index(g, "## [v" v "]") == 1) { found = 1; break }
            kept[++k] = g
        }
        if (!found) fail("cog changelog has no section for v" v "; is the history complete?")
        # Drop the separator and blank lines cog leaves ahead of the section that was cut.
        while (k > 0 && (kept[k] == "" || kept[k] == "- - -")) k--
        if (k == 0) fail("cog changelog produced no releases before v" v "; refusing to write the changelog")

        for (i = 1; i <= first; i++) print line[i]
        for (i = 1; i <= k; i++) print kept[i]
        print ""
        for (i = last; i <= n; i++) print line[i]
    }
' "$path" > "$out"

cp "$out" "$path"
echo "wrote $path"
