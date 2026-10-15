#!/bin/sh
# rebuild-unchanged.sh — a second build of an unchanged tree leaves every document unchanged.
#
#   sh .github/rebuild-unchanged.sh
#
# Run by CI's two build jobs, after a first `just all`. An unchanged page keeps its stamp:
# build reads the old one back from the PDF. A second build must therefore report every
# document unchanged, and a stamp it cannot read back re-stamps every page and shows here.
#
# It reads all's summary line, `press: N documents: N unchanged`, rather than each
# document's own line. Checking only for a changed document line would pass a run that
# printed none, for want of anything to object to.
set -eu
out=$(just all)
printf '%s\n' "$out"
printf '%s\n' "$out" | tail -n 1 | awk '
    $1 == "press:" && $2 == $4 && $5 == "unchanged" && NF == 5 { ok = 1 }
    END { exit !ok }' \
    || { echo "::error::a rebuild of an unchanged tree did not report every document unchanged"; exit 1; }
