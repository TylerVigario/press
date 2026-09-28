#!/bin/sh
# stamp.sh — compile a document, stamped with when its content last changed.
#
# Invoked by press's `build` recipe, and by check.sh for its recompile, from the
# consumer root:
#
#   sh <press_root>/tools/stamp.sh <doc> <pdf> <typst flags...>
#
# NOT A WRAPPER. `just build` stays the one way to build; this file is to the build recipe
# what check.sh is to check -- its mechanism, kept in a file for the cygpath reason below.
#
# WHY A STAMP. A printed sheet goes stale without saying so. The stamp is passed in as
# sys.inputs.press-updated, and a document shows it with the package's updated() — in
# its footer, so every page carries it. Comparing the shelf copy with the latest build
# then answers "reprint?" at a glance.
#
# WHY "LAST CHANGED", NOT "BUILT". A rebuild that changes nothing would otherwise move the
# time, and a newer time would say "reprint" about an identical page. So the source is
# first compiled AT the previous stamp: typst's output is deterministic for the same
# inputs and --creation-timestamp, so a byte-identical PDF means nothing on the page
# changed, and the old time stands. Only a
# difference compiles again at the current time. A different typst, or new fonts, can
# change the bytes of an unchanged page; that re-stamps it, which errs toward reprinting.
#
# The previous stamp is read from the PDF itself: --creation-timestamp puts it in the Info
# dictionary as plain text, /CreationDate(D:YYYYMMDDHHMMSSZ), in UTC. No side file to lose
# or leave behind. A PDF without one -- or built before this -- simply gets a new stamp.
#
# A plain file handed to sh, like check.sh, and for the same reason: a recipe with a
# shebang goes through cygpath on Windows and does not run from PowerShell.
set -eu

src=$1
pdf=$2
shift 2
# What remains in "$@" is typst_flags, as in check.sh.

now=$(date +%s)

# Local time, readable on paper. GNU date (Linux, Git for Windows) takes -d @N; BSD and
# macOS take -r N.
when() { date -d "@$1" '+%Y-%m-%d %H:%M %Z' 2>/dev/null || date -r "$1" '+%Y-%m-%d %H:%M %Z'; }

# The previous stamp, in Unix seconds, from the PDF's own /CreationDate; empty if none.
# awk does the calendar arithmetic (days from civil, Hinnant) because GNU and BSD date
# disagree on how to parse a date, and this must run on both.
stamp_of() {
    grep -a -o '/CreationDate(D:[0-9]\{14\}Z)' "$1" 2>/dev/null | head -n 1 | awk '{
        s = substr($0, index($0, "D:") + 2, 14)
        y = substr(s, 1, 4) + 0; m = substr(s, 5, 2) + 0; d = substr(s, 7, 2) + 0
        if (m <= 2) { y -= 1; m += 12 }
        era = int(y / 400); yoe = y - era * 400
        doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + int((153 * (m - 3) + 2) / 5) + d - 1
        printf "%d\n", (era * 146097 + doe - 719468) * 86400 + substr(s, 9, 2) * 3600 + substr(s, 11, 2) * 60 + substr(s, 13, 2)
    }'
}

# Compile $src at stamp $1 into $2; typst's own output goes to stdout for the caller.
at() {
    e=$1; o=$2; shift 2
    typst compile "$@" --input "press-updated=$(when "$e")" --creation-timestamp "$e" "$src" "$o" 2>&1
}

mkdir -p "$(dirname "$pdf")"

old=$( [ -f "$pdf" ] && stamp_of "$pdf" || true )
if [ -n "$old" ]; then
    # typst takes the format from the extension, so the trial build keeps .pdf.
    tmp="${pdf%.pdf}.press-trial.$$.pdf"
    if out=$(at "$old" "$tmp" "$@"); then
        if cmp -s "$tmp" "$pdf"; then
            rm -f "$tmp"
            [ -n "$out" ] && printf '%s\n' "$out" >&2
            exit 0
        fi
    else
        rm -f "$tmp"
        printf '%s\n' "$out" >&2
        exit 1
    fi
    rm -f "$tmp"
fi

if out=$(at "$now" "$pdf" "$@"); then
    [ -n "$out" ] && printf '%s\n' "$out" >&2
    exit 0
fi
printf '%s\n' "$out" >&2
exit 1
