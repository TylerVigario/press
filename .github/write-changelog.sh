#!/bin/sh
# write-changelog.sh — regenerate CHANGELOG.md at a release, keeping its hand-written
# first release, and print the new release's notes.
#
# Run by the release workflow, in the dry run's preview and again when it publishes, in the
# runner's clone:
#
#   sh .github/write-changelog.sh <tag> [CHANGELOG.md] > notes.md
#
# Between the FIRST and the LAST `- - -` line the file is cog's full `cog changelog`,
# rewritten at every release. The preamble above the first separator and everything from
# the last one on are kept verbatim. Below the last is the first release, written by hand
# as "Initial release.": a first release has no earlier version to differ from, but cog
# renders it as every commit since the repository began, compared from the first commit
# (cocogitto/cocogitto#580). cog's own section for that version is dropped.
#
# THE DATE. cog names a section only after a tag, and dates it by the commit the tag is on.
# The release's tag does not exist yet, and set on HEAD — the last change merged — it would
# date the release by that merge instead (cocogitto/cocogitto#579, met first in
# greenroom-win). So the tag goes on an empty commit made now, as greenroom-win's goes on
# the bump commit it makes; the forge's release commit follows within minutes. When HEAD
# already is that release commit — a new run after a failed publish — the tag goes on it,
# and the changelog comes out exactly as it was recorded. The commit and the tag exist in
# this clone only and are gone before this exits; CHANGELOG.md keeps the result.
#
# The release notes, on stdout, are the new version's section without the separator cog
# closes it with.
#
# The same method as greenroom-win's ci/write-changelog.ps1. Both go when #580 is fixed.
#
# COG_CHANGELOG names a file to read cog's output from instead of running cog, so the
# joining can be tested without a repository.
set -eu

tag=${1:?usage: write-changelog.sh <tag> [CHANGELOG.md]}
path=${2:-CHANGELOG.md}
gen=$(mktemp)
out=$(mktemp)
made=
# Undo what was made even when a step fails half-way, so the clone is left as it was found.
cleanup() {
    rm -f "$gen" "$out"
    if [ -n "$made" ]; then git tag -d "$tag" >/dev/null 2>&1 || true; fi
    if [ "$made" = commit ]; then git reset -q --soft HEAD~1; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [ -n "${COG_CHANGELOG:-}" ]; then
    cp "$COG_CHANGELOG" "$gen"
else
    # Signing is off for both: they are never pushed, and a machine that signs by default
    # would otherwise stop here asking for a tag message.
    if [ "$(git log -1 --format=%s)" = "release: $tag" ]; then
        made=tag
    else
        git -c user.name=press-release -c user.email=noreply@github.com -c commit.gpgSign=false \
            commit -q --allow-empty --no-verify -m "release: $tag (local, never pushed)"
        made=commit
    fi
    git -c tag.gpgSign=false tag "$tag"
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
echo "wrote $path" >&2

awk '/^## /{n++} n==1 { line[++k] = $0 }
     END { while (k > 0 && (line[k] == "" || line[k] == "- - -")) k--
           for (i = 1; i <= k; i++) print line[i] }' "$gen"
