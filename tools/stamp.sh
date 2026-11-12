#!/bin/sh
# stamp.sh — compile a document, stamped with when its content last changed.
#
# Run from the consumer root by build.sh, which any runner calls, and by check.sh for its
# recompile:
#
#   sh <press_root>/tools/stamp.sh <doc> <pdf> <typst flags...>
#
# On success it prints one line, which build.sh hands to report.sh: what
# happened -- new (no stamped PDF was there), changed, unchanged (built again, and the same
# bytes or the same pages) or cached (the build record matched, so nothing was built) -- then the time the page now
# carries. typst's own output goes to stderr.
#
# IT IS THE BUILD, not a wrapper around one: every runner calls it, and check.sh compiles
# through it too, so the audit reads a PDF built exactly as the build makes it.
#
# EVERY BUILD IS AUDITED. Once the PDF is written, check.sh's passes read it, with the files
# this compile read and the warnings it printed, so nothing compiles twice. A finding prints
# and fails the build, and the PDF stays written, so a runner, CI or `all` sees it and the page
# can still be looked at. Where the audit's tools are missing, the build says the audit was
# skipped and why, and succeeds: building never depends on them. check.sh's own compile is not
# audited again (PRESS_IN_CHECK).
#
# WHY A STAMP. A printed sheet goes stale without saying so. The stamp is passed in as
# sys.inputs.press-updated, and a document shows it with updated(), in lib/parts.typ — in
# its footer, so every page carries it. Comparing the shelf copy with the latest build
# then answers "reprint?" at a glance.
#
# WHY "LAST CHANGED", NOT "BUILT". A rebuild that changes nothing would otherwise move the
# time, and a newer time would say "reprint" about an identical page. So the source is
# first compiled AT the previous stamp: typst's output is deterministic for the same
# inputs and --creation-timestamp, so a byte-identical PDF means nothing on the page
# changed, and the old time stands. Only a difference compiles again at the current time.
#
# WHAT THE PAGE SHOWS, NOT THE BYTES. Different bytes do not mean a different page. A press
# release that builds a part another way, a different typst, or a font file rewritten without
# a glyph changing, each changes the bytes of every document they reach, and on paper nothing
# moved. A new time there would tell the reader comparing two copies, which is what the stamp is
# for, that the content changed when it did not. So where the bytes differ, the two PDFs are
# read as they print: their words first, which an edit almost always changes and which are
# cheap to read, then every page drawn at the audit's 150 dpi, one page at a time, and compared
# pixel for pixel. The same on every page, the new build is kept at the old time. That needs
# poppler's pdftoppm; without it, different bytes re-stamp the page as before, erring toward
# reprinting, and building still never depends on the audit's tools.
#
# The previous stamp is read from the PDF itself: --creation-timestamp puts it in the Info
# dictionary as plain text, /CreationDate(D:YYYYMMDDHHMMSSZ), in UTC. No side file to lose
# or leave behind. A PDF without one -- or built before this -- simply gets a new stamp.
#
# typst 0.14 writes a space before the date's parenthesis, and stamp_of reads either.
set -eu

src=$1
pdf=$2
shift 2
# What remains in "$@" is the typst flags, as in check.sh.

# The oldest typst press works with, from press.toml. lib/tokens.typ asserts it too, but build
# and check pass --creation-timestamp and --deps first, and an older typst stops on a flag it
# lacks, as "unexpected argument", before press is ever read.
min=$(sed -n 's/^typst *= *"\(.*\)"$/\1/p' "$(dirname "$0")/../press.toml")
v=$(typst --version) || { echo 'press: typst is not on PATH' >&2; exit 1; }
v=${v#typst }
v=${v%% *}
echo "$v" | awk -F. -v min="$min" '{
    split(min, m, ".")
    for (i = 1; i <= 3; i++) { if ($i + 0 > m[i] + 0) exit 0; if ($i + 0 < m[i] + 0) exit 1 }
}' || { echo "press: needs typst $min or newer; this is typst $v" >&2; exit 1; }

# SOURCE_DATE_EPOCH, where it is set, is the build's time, as the specification says
# (https://reproducible-builds.org/specs/source-date-epoch/): "Build processes MUST use this
# variable for embedded timestamps in place of the "current" date and time", and a timestamp
# that is not current is "no later than the value of this variable". A page changed or new is
# stamped with it, and one kept unchanged keeps its stamp, or comes back to it where the stamp
# is later. A value that is not a whole number of seconds stops the build; set but empty, which
# the specification does not cover, it is as if unset.
now=$(date +%s)
sde=${SOURCE_DATE_EPOCH:-}
case $sde in
    '') ;;
    *[!0-9]*)
        echo "press: SOURCE_DATE_EPOCH is $sde, not a whole number of seconds since 1970," \
            "as date +%s prints" >&2
        exit 1 ;;
    *) now=$sde ;;
esac

# The stamp is kept and compared in UTC -- the PDF's /CreationDate -- and printed in the
# REPOSITORY's time zone, an IANA name its .press.toml gives, at the root the tools run from:
#
#   timezone = "America/Los_Angeles"     ("UTC" for documents read across zones)
#
# so every machine prints the same text for the same moment, and an unchanged page stays
# unchanged wherever it is built, by whatever runs the build. The zone is the repository's, the
# same for each of its documents and each build of them, so it is written once, where every
# build reads it, as a site's is in Hugo's or Jekyll's configuration. PRESS_TZ overrides the file
# for a build, and --tz, which build.sh and all.sh take, overrides both. With none naming a zone
# the stamp prints in UTC, never the building machine's own zone, which would re-stamp an
# unchanged page each time a machine in another zone built it.
#
# .press.toml is a small part of TOML: each line blank, a # comment, or a setting, name = "value"
# or name = 'value', a comment after it if any. A line that is none of those, a name press does
# not know or one given twice fails the build, rather than leaving a setting unread and the
# page in UTC. Its own name keeps it apart from press.toml, the kit's, which marks press's
# folder.
settings=.press.toml
setting() {
    LC_ALL=C awk -v want="$1" -v sq="'" -v file="$settings" '
        function bad(why) { printf "press: %s, line %d: %s\n       %s\n", file, NR, why, $0 > "/dev/stderr"; fail = 1 }
        NR == 1 { sub(/^\357\273\277/, "") }
        { sub(/\r$/, "") }
        /^[ \t]*(#.*)?$/ { next }
        !match($0, /^[ \t]*[A-Za-z0-9_-]+[ \t]*=[ \t]*/) { bad("not a setting, name = \"value\""); next }
        {
            name = substr($0, 1, RLENGTH); sub(/^[ \t]*/, "", name); sub(/[ \t]*=.*$/, "", name)
            v = substr($0, RLENGTH + 1)
            if (v ~ /^"[^"\\]*"[ \t]*(#.*)?$/) q = "\""
            else if (v ~ ("^" sq "[^" sq "]*" sq "[ \t]*(#.*)?$")) q = sq
            else { bad("its value is not one quoted string"); next }
            v = substr(v, 2); v = substr(v, 1, index(v, q) - 1)
            if (name != "timezone") { bad("press has no setting " name "; it has timezone"); next }
            if (name in seen) { bad(name " is set twice"); next }
            seen[name] = 1
            if (name == want) found = v
        }
        END { if (fail) exit 1; if (found != "") print found }
    ' "$settings"
}
# The file is read whenever it is there, so a fault in it fails every build, not only one
# without PRESS_TZ.
name=
if [ -f "$settings" ]; then name=$(setting timezone) || exit 1; fi
from="$settings's timezone"
if [ -n "${PRESS_TZ:-}" ]; then name=$PRESS_TZ from="PRESS_TZ (or --tz)"; fi
# date is handed the zone's FILE, not its name. Git for Windows' date knows no names: its
# database is /mingw64/share/zoneinfo, where its date neither looks nor follows TZDIR, but it
# reads a zone file given by path, as glibc, the BSDs and macOS do. A name or path date
# cannot read is no error to date either: it prints UTC under a made-up name. So the file is
# found first, and a name with none fails the build. UTC with no zone named is POSIX's UTC0,
# which needs no file.
zone=UTC0
if [ -n "$name" ]; then
    zone=
    for dir in ${TZDIR:+"$TZDIR"} /usr/share/zoneinfo /mingw64/share/zoneinfo; do
        if [ -f "$dir/$name" ]; then
            zone=:$dir/$name
            break
        fi
    done
    if [ -z "$zone" ]; then
        echo "press: $from is not a time zone this machine knows: $name" >&2
        echo "       looked in ${TZDIR:+$TZDIR, }/usr/share/zoneinfo and /mingw64/share/zoneinfo;" >&2
        echo "       set TZDIR if this machine keeps its zones elsewhere" >&2
        exit 1
    fi
fi
tz() { TZ=$zone "$@"; }

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

# The audit's working files: the files the compile read, and what typst printed.
work=$(mktemp -d "${TMPDIR:-/tmp}/press-build.XXXXXX")
trial=
trap 'rm -rf "$work"; if [ -n "$trial" ]; then rm -f "$trial"; fi' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# PRESS_PDFTOPPM and PRESS_PDFTOTEXT name poppler's binaries where PATH cannot, as for the audit.
PDFTOPPM=${PRESS_PDFTOPPM:-pdftoppm}
PDFTOTEXT=${PRESS_PDFTOTEXT:-pdftotext}
# The page count from the PDF's page tree, which typst writes uncompressed, as report.sh reads it.
pages_of() { tr '\r\n' '  ' < "$1" | grep -a -o '/Type */Pages */Count *[0-9]*' | sed 's/.*Count *//' | sort -n | tail -n 1; }
# prints_same <a.pdf> <b.pdf>: every page of the two draws the same pixels. Fails where they
# differ, and where it cannot tell: no pdftoppm, or a page count it cannot read. Each page's
# raster is replaced by the next, so the space it takes stays one page's.
prints_same() {
    command -v "$PDFTOPPM" >/dev/null 2>&1 || return 1
    n=$(pages_of "$1")
    [ -n "$n" ] && [ "$n" = "$(pages_of "$2")" ] || return 1
    # Any pdftotext will do here, poppler's or not: the same one reads both.
    if command -v "$PDFTOTEXT" >/dev/null 2>&1 \
            && "$PDFTOTEXT" -layout "$1" "$work/a.txt" 2>/dev/null \
            && "$PDFTOTEXT" -layout "$2" "$work/b.txt" 2>/dev/null; then
        cmp -s "$work/a.txt" "$work/b.txt" || return 1
    fi
    i=1
    while [ "$i" -le "$n" ]; do
        "$PDFTOPPM" -r 150 -f "$i" -l "$i" -singlefile "$1" "$work/a" 2>/dev/null \
            && "$PDFTOPPM" -r 150 -f "$i" -l "$i" -singlefile "$2" "$work/b" 2>/dev/null \
            && cmp -s "$work/a.ppm" "$work/b.ppm" || return 1
        i=$((i + 1))
    done
}

# THE BUILD RECORD. A PDF is unchanged only if nothing it was made from changed, and that is
# known without compiling it. One file in press's own folder, .build-record, holds an entry per
# document and PDF: what its last build read -- every file typst lists, the fonts in each font
# path (typst does not list fonts), the typst version, press's tools, the flags, the zone --
# with a SHA-256 of each, the PDF's own, its stamp, and what the audit said. When all of it still
# matches, the build says cached without compiling or auditing again, and repeats what the
# audit said. Only a build whose audit ran every pass and passed is recorded: one that failed, or
# skipped anything for want of a tool, has its entry removed, so the next build audits again.
#
# The record is a cache. press's .gitignore keeps it out of git, an update replaces press's
# folder and the record with it, and deleting it costs one full build per document, never a
# wrong answer. A record press cannot write leaves the build as it was. check.sh, the audit asked
# for by name, never uses it. Two builds at once each write a whole new record and the later
# one stands, which costs the other document a rebuild.
here=$(dirname "$0")
record=$here/../.build-record
entry_head=$(printf '== %s\t%s' "$src" "$pdf")
# entry: this document's entry from the record, without its heading.
entry() { [ -f "$record" ] && awk -v h="$entry_head" '$0 == h { on = 1; next } /^== / { on = 0 } on' "$record"; }
# others: the record without this document's entry.
others() {
    if [ -f "$record" ]; then
        awk -v h="$entry_head" '/^== / { on = ($0 != h) } NR == 1 || on' "$record"
    else
        echo "press build record 1"
    fi
}
# write_record: replace the record with what is on stdin, whole, or leave it if press's folder
# cannot be written.
write_record() { cat > "$record.$$" 2>/dev/null && mv "$record.$$" "$record" 2>/dev/null || rm -f "$record.$$" 2>/dev/null || true; }
if command -v sha256sum >/dev/null 2>&1; then dig=sha256sum; else dig="shasum -a 256"; fi
# fontdirs <typst flags...>: the font paths a build reads, from the flags and the environment.
fontdirs() {
    want=
    for a in "$@"; do
        if [ -n "$want" ]; then printf '%s\n' "$a"; want=; continue; fi
        case $a in
            --font-path) want=1 ;;
            --font-path=*) printf '%s\n' "${a#--font-path=}" ;;
        esac
    done
    if [ -n "${TYPST_FONT_PATHS:-}" ]; then printf '%s\n' "$TYPST_FONT_PATHS" | tr ':;' '\n\n'; fi
}
# key <typst flags...>: what the build depends on besides the files typst lists.
key() {
    echo "typst $(typst --version)"
    printf 'flags'; printf ' %s' "$@"; echo
    echo "zone $zone"
    echo "env ${TYPST_ROOT-}|${TYPST_FONT_PATHS-}|${TYPST_IGNORE_SYSTEM_FONTS-}"
    # shellcheck disable=SC2086  # $dig is a command and its arguments
    $dig "$here/stamp.sh" "$here/check.sh" "$here/ink-margin.py" "$here/line-overlap.py" | sed 's/^/tool /'
    # shellcheck disable=SC2086  # $dig is a command and its arguments
    fontdirs "$@" | while IFS= read -r d; do
        [ -d "$d" ] && find "$d" -type f \( -name '*.[ot]tf' -o -name '*.tt[c]' -o -name '*.ot[c]' \)
    done | LC_ALL=C sort | tr '\n' '\000' | xargs -0 $dig 2>/dev/null | sed 's/^/font /'
}
if [ -z "${PRESS_IN_CHECK:-}" ] && [ -z "${PRESS_STAMP_AS:-}" ]; then
    key "$@" > "$work/key"
    entry > "$work/entry" || true
    if [ -s "$work/entry" ] && [ -f "$pdf" ]; then
        # shellcheck disable=SC2086
        { cat "$work/key"; echo "pdf $($dig "$pdf" | cut -d ' ' -f 1)"; } > "$work/now"
        sed -n 's/^input //p' "$work/entry" > "$work/inputs"
        # SOURCE_DATE_EPOCH is not in the key: it stamps only a page that changed, which the
        # record never holds, and a recorded stamp later than it is built again, to come back.
        # shellcheck disable=SC2086
        if head -n "$(wc -l < "$work/now")" "$work/entry" | cmp -s - "$work/now" \
                && [ -s "$work/inputs" ] && $dig -c --status "$work/inputs" 2>/dev/null \
                && { [ -z "$sde" ] \
                    || [ "$(sed -n 's/^stamp //p' "$work/entry")" -le "$sde" ]; }; then
            sed -n 's/^note //p' "$work/entry" >&2
            printf 'cached %s\n' "$(when "$(sed -n 's/^stamp //p' "$work/entry")")"
            exit 0
        fi
    fi
    if [ -s "$work/entry" ]; then others | write_record; fi
fi
[ -n "${PRESS_IN_CHECK:-}" ] || set -- "$@" --deps "$work/deps" --deps-format zero

# finish <status> <stamp> <typst flags...>: say what typst printed and what the build made,
# then audit it; record the build if the audit passed, and exit with the audit's answer.
finish() {
    st=$1 stamp=$2
    shift 2
    [ -n "$out" ] && printf '%s\n' "$out" >&2
    printf '%s %s\n' "$st" "$(when "$stamp")"
    [ -z "${PRESS_IN_CHECK:-}" ] || exit 0
    printf '%s\n' "$out" > "$work/log"
    s=0
    PRESS_AUDIT=optional PRESS_BUILT_DEPS="$work/deps" PRESS_BUILT_LOG="$work/log" PRESS_AUDIT_RAN="$work/ran" \
        sh "$here/check.sh" "$src" "$pdf" "$here/.." "$@" 2> "$work/notes" || s=$?
    cat "$work/notes" >&2
    [ "$s" -eq 0 ] || exit "$s"
    [ -f "$work/ran" ] || exit 0
    # shellcheck disable=SC2086
    {
        others
        printf '%s\n' "$entry_head"
        cat "$work/key"
        echo "pdf $($dig "$pdf" | cut -d ' ' -f 1)"
        echo "stamp $stamp"
        tr '\000\\' '\n/' < "$work/deps" | while IFS= read -r f; do
            if [ -n "$f" ] && [ -f "$f" ]; then printf '%s\000' "$f"; fi
        done | xargs -0 $dig | sed 's/^/input /'
        sed 's/^/note /' "$work/notes"
    } | write_record
    exit 0
}

# Compile $src at stamp $1 into $2; typst's own output goes to stdout for the caller.
at() {
    e=$1; o=$2; shift 2
    typst compile "$@" --input "press-updated=$(when "$e")" --creation-timestamp "$e" "$src" "$o" 2>&1
}

mkdir -p "$(dirname "$pdf")"

# A copy at another PDF's stamp (PRESS_STAMP_AS): check's copy with every scan hidden, which
# must lay out exactly as the document's PDF does, stamp and all. No comparison, no audit.
if [ -n "${PRESS_STAMP_AS:-}" ]; then
    e=$(stamp_of "$PRESS_STAMP_AS")
    [ -n "$e" ] || e=$now
    out=$(at "$e" "$pdf" "$@") || { printf '%s\n' "$out" >&2; exit 1; }
    exit 0
fi

old=$( [ -f "$pdf" ] && stamp_of "$pdf" || true )
# keep <typst flags...>: the page is unchanged, and keeps its stamp, or comes back to
# SOURCE_DATE_EPOCH where the stamp is later.
keep() {
    if [ -n "$sde" ] && [ "$old" -gt "$sde" ]; then
        out=$(at "$now" "$pdf" "$@") || { printf '%s\n' "$out" >&2; exit 1; }
        finish unchanged "$now" "$@"
    fi
    finish unchanged "$old" "$@"
}
if [ -n "$old" ]; then
    # typst takes the format from the extension, so the trial build keeps .pdf. It sits in
    # print/, so an interrupt mid-compile removes it rather than leaving it there.
    trial="${pdf%.pdf}.press-trial.$$.pdf"
    if out=$(at "$old" "$trial" "$@"); then
        if cmp -s "$trial" "$pdf"; then
            rm -f "$trial"
            keep "$@"
        fi
        # Other bytes, the same pages: the new build is the PDF, at the old time.
        if prints_same "$trial" "$pdf"; then
            mv -f "$trial" "$pdf"
            trial=
            keep "$@"
        fi
    else
        rm -f "$trial"
        printf '%s\n' "$out" >&2
        exit 1
    fi
    rm -f "$trial"
fi

if out=$(at "$now" "$pdf" "$@"); then
    finish "$( [ -n "$old" ] && echo changed || echo new )" "$now" "$@"
fi
printf '%s\n' "$out" >&2
exit 1
