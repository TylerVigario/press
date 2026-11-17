#!/bin/sh
# units-gap.sh — units() sets its units `spacing` apart under every pack, whatever paragraph
# spacing the document sets, and "stacks" counts those gaps when it balances its columns.
#
#   sh .github/units-gap.sh
#
# Run by CI on press's typst and on the oldest toolchain. .github/units-gap.typ measures the gap
# under "single", "stacks" and "grid" under a tight spacing and a loose one, and sets four units
# under "stacks" whose second goes in the left column only if the gaps between units count.
set -eu
cd "$(dirname "$0")/.."

fail() { echo "units-gap: $*" >&2; exit 1; }

# value <spacing> <label>: what the probe holds under that label.
value() {
    typst query --root . --font-path fonts --ignore-system-fonts --input "spacing=$1" \
        .github/units-gap.typ "<$2>" --field value 2>/dev/null | tr -d '[]" \n'
}
for spacing in 0.55em 2em; do
    gaps=$(value "$spacing" gaps)
    [ -n "$gaps" ] || fail "the probe measured nothing"
    [ "$gaps" = "{single:6pt,stacks:6pt,grid:6pt}" ] ||
        fail "units sit $gaps apart under $spacing paragraph spacing, not 6pt under each pack"
    [ "$(value "$spacing" balance)" = "true" ] ||
        fail "\"stacks\" split its units where its columns are not most level," \
            "under $spacing paragraph spacing"
done
echo "units-gap: units sit their spacing apart under every pack, and \"stacks\" counts it"
