#!/bin/sh
# zone.sh — the stamp prints in the zone the repository's .press.toml names, under PRESS_TZ and
# --tz, and in UTC with none, whatever zone the building machine is in.
#
#   sh .github/zone.sh
#
# Run by CI on press's typst and on the oldest toolchain. A scratch repository holds a copy of the
# kit under third_party/press, as the README installs it, and one brief, whose footer prints the
# stamp, built with build.sh and no runner, each time from a shell in another zone (TZ), as a
# second machine or CI would be:
#
#   · with no .press.toml and no PRESS_TZ, the stamp prints in UTC, not the machine's zone;
#   · with .press.toml naming a zone, written with CRLF and comments as an editor on Windows
#     might, it prints in that zone, and a build from a machine in another zone leaves the page
#     unchanged;
#   · PRESS_TZ prints in its zone over the file, and --tz in its own over both;
#   · a line it cannot read, a name it does not know, one given twice or a zone the machine does
#     not know fails the build with a line naming the file, PRESS_TZ set or not.
#
# The zones keep no daylight time, so each always prints the same name: JST, IST.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "zone: $*" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

repo=$tmp/repo
mkdir -p "$repo/third_party/press" "$repo/docs"
cp -R lib.typ lib press.toml template calibration.typ fonts tools "$repo/third_party/press/"
printf '#import "/third_party/press/lib.typ": *\n#show: brief.with(title: [Note], author: "Sam Example")\n\nOne line.\n' \
    > "$repo/docs/note.typ"
cd "$repo"

# build <machine zone> [env...] -- [build.sh flags...]: build the document from a shell in that
# zone; prints build.sh's line, and its errors, and fails as it does.
build() {
    machine=$1; shift
    env TZ="$machine" "$@" sh third_party/press/tools/build.sh docs/note.typ 2>&1
}
# zone_of <line>: the zone a build's line ends with, the stamp's.
zone_of() { printf '%s\n' "$1" | sed -n 's/^print\/docs\/note\.pdf: .* \([A-Z][A-Z]*\)$/\1/p'; }
# expect <what> <zone> <line>
expect() {
    z=$(zone_of "$3")
    [ "$z" = "$2" ] || { printf '%s\n' "$3" >&2; fail "$1 printed the stamp in ${z:-no zone}, not $2"; }
    echo "zone: $1 prints in $2"
}

out=$(build America/New_York) || { printf '%s\n' "$out" >&2; fail "a build with no zone named failed"; }
expect "a build with no zone named, on a machine in New York," UTC "$out"

printf '# The zone the stamp prints in.\r\ntimezone = "Asia/Tokyo"  # Japan keeps no daylight time\r\n' > .press.toml
out=$(build America/New_York) || { printf '%s\n' "$out" >&2; fail "a build with .press.toml failed"; }
expect ".press.toml's timezone, on a machine in New York," JST "$out"
rm -f third_party/press/.build-record
out=$(build Europe/Berlin) || { printf '%s\n' "$out" >&2; fail "a second build with .press.toml failed"; }
expect ".press.toml's timezone, on a machine in Berlin," JST "$out"
case $out in
    *": unchanged, "*) echo "zone: a build on a machine in another zone leaves the page unchanged" ;;
    *) printf '%s\n' "$out" >&2; fail "a build on a machine in another zone did not leave the page unchanged" ;;
esac

out=$(build Europe/Berlin PRESS_TZ=UTC) || { printf '%s\n' "$out" >&2; fail "a build with PRESS_TZ failed"; }
expect "PRESS_TZ, over .press.toml," UTC "$out"
out=$(TZ=Europe/Berlin PRESS_TZ=UTC sh third_party/press/tools/build.sh --tz Asia/Kolkata docs/note.typ 2>&1) \
    || { printf '%s\n' "$out" >&2; fail "a build with --tz failed"; }
expect "--tz, over PRESS_TZ and .press.toml," IST "$out"

# refused <what> <.press.toml's text>: a build with that file fails, and says so naming the file,
# with PRESS_TZ set or not.
refused() {
    printf '%s\n' "$2" > .press.toml
    for env in TZ=UTC PRESS_TZ=UTC; do
        if out=$(build UTC "$env"); then
            printf '%s\n' "$out" >&2; fail "a build with $1 in .press.toml, and $env, passed"
        fi
        case $out in
            *".press.toml"*) ;;
            *) printf '%s\n' "$out" >&2; fail "a build with $1 in .press.toml failed without naming the file" ;;
        esac
    done
    echo "zone: a build with $1 in .press.toml fails, naming the file"
}
refused "a name press does not know" 'zone = "Asia/Tokyo"'
refused "a value not quoted" 'timezone = Asia/Tokyo'
refused "a line that is no setting" 'timezone'
refused "a name given twice" "$(printf 'timezone = "Asia/Tokyo"\ntimezone = "UTC"')"
# Without PRESS_TZ only: with it, the file's zone is not the one used, and the name is PRESS_TZ's.
printf 'timezone = "Mars/Olympus_Mons"\n' > .press.toml
if out=$(build UTC); then printf '%s\n' "$out" >&2; fail "a build with a zone the machine does not know passed"; fi
case $out in
    *".press.toml's timezone is not a time zone this machine knows: Mars/Olympus_Mons"*)
        echo "zone: a build with a zone the machine does not know fails, naming the file" ;;
    *) printf '%s\n' "$out" >&2; fail "a build with a zone the machine does not know failed without naming the file" ;;
esac
