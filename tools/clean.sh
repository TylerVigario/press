#!/bin/sh
# clean.sh — delete what the builds made: print/, under the project root.
#
# Run from the project root, by whatever runs the repo's builds; press.just's `clean` is this:
#
#   sh third_party/press/tools/clean.sh
#
# A tool of its own because a runner on Windows runs its scripts in cmd.exe, which has no rm.
# press's build record lives in press's folder, not here, and the stamps in .press-stamps at the
# root, so both stay: a build after this compiles each document again, since its PDF is gone, and
# an unchanged page keeps its stamp.
set -eu

rm -rf print
