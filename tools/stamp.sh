#!/bin/sh
# stamp.sh — compile a document, stamped with when its content last changed.
#
# Invoked by press's `build` recipe, and by check.sh for its recompile, from the
# consumer root:
#
#   sh <press_root>/tools/stamp.sh <doc> <pdf> <typst flags...>
#
# On success it prints one line, which `build` hands to report.sh: what happened -- new (no
# stamped PDF was there), changed or unchanged -- then the time the page now carries.
# typst's own output goes to stderr.
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

# The stamp is kept and compared in UTC -- the PDF's /CreationDate -- and printed in the
# DOCUMENT's time zone: PRESS_TZ, an IANA name the consuming repo exports from its justfile,
#
#   export PRESS_TZ := "America/Los_Angeles"     ("UTC" for documents read across zones)
#
# so every machine prints the same text for the same moment, and an unchanged page stays
# unchanged wherever it is built. Unset, it is the building machine's own zone, and a build
# under another zone re-stamps a page that did not change.
#
# date is handed the zone's FILE, not its name. Git for Windows' date knows no names: its
# database is /mingw64/share/zoneinfo, where its date neither looks nor follows TZDIR, but it
# reads a zone file given by path, as glibc, the BSDs and macOS do. A name or path date
# cannot read is no error to date either: it prints UTC under a made-up name. So the file is
# found first, and a name with none fails the build.
zone=
if [ -n "${PRESS_TZ:-}" ]; then
    for dir in ${TZDIR:+"$TZDIR"} /usr/share/zoneinfo /mingw64/share/zoneinfo; do
        if [ -f "$dir/$PRESS_TZ" ]; then
            zone=$dir/$PRESS_TZ
            break
        fi
    done
    if [ -z "$zone" ]; then
        echo "press: PRESS_TZ is not a time zone this machine knows: $PRESS_TZ" >&2
        echo "       looked in ${TZDIR:+$TZDIR, }/usr/share/zoneinfo and /mingw64/share/zoneinfo;" >&2
        echo "       set TZDIR if this machine keeps its zones elsewhere" >&2
        exit 1
    fi
fi
tz() { if [ -n "$zone" ]; then TZ=":$zone" "$@"; else "$@"; fi; }

# Readable on paper. GNU date (Linux, Git for Windows) takes -d @N; BSD and macOS take -r N.
when() { tz date -d "@$1" '+%Y-%m-%d %H:%M %Z' 2>/dev/null || tz date -r "$1" '+%Y-%m-%d %H:%M %Z'; }

# The previous stamp, in Unix seconds, from the PDF's own /CreationDate; empty if none.
# typst 0.14 writes a space before the date's parenthesis and 0.15 none, so either is read.
# awk does the calendar arithmetic (days from civil, Hinnant) because GNU and BSD date
# disagree on how to parse a date, and this must run on both.
stamp_of() {
    grep -a -o '/CreationDate *(D:[0-9]\{14\}Z)' "$1" 2>/dev/null | head -n 1 | awk '{
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
    # typst takes the format from the extension, so the trial build keeps .pdf. It sits in
    # print/, so an interrupt mid-compile removes it rather than leaving it there.
    tmp="${pdf%.pdf}.press-trial.$$.pdf"
    trap 'rm -f "$tmp"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    if out=$(at "$old" "$tmp" "$@"); then
        if cmp -s "$tmp" "$pdf"; then
            rm -f "$tmp"
            [ -n "$out" ] && printf '%s\n' "$out" >&2
            printf 'unchanged %s\n' "$(when "$old")"
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
    printf '%s %s\n' "$( [ -n "$old" ] && echo changed || echo new )" "$(when "$now")"
    exit 0
fi
printf '%s\n' "$out" >&2
exit 1
