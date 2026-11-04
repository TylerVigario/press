#!/bin/sh
# embedded-shell.sh — writes out the shell that lives outside a *.sh file, so shellcheck can read
# it: each recipe of press.just, and each run: block of the composite action every CI job uses.
#
#   sh .github/embedded-shell.sh <dir>
#
# Run by CI's Shell scripts lint, which then checks what it writes with the *.sh files. actionlint
# checks a workflow's run: blocks but not a composite action's, and no *.sh pattern finds a recipe.
# A recipe comes from just's own dump of it, so it is read as just reads it. Its interpolations are
# each a quote() call, one quoted word in the shell, and are written as 'x'; anything else in
# braces is written as x. A recipe runs under sh, and the action's blocks under the bash their
# shell: names.
set -eu
cd "$(dirname "$0")/.."
[ $# -eq 1 ] && [ -d "$1" ] || { echo "embedded-shell.sh needs a directory to write into" >&2; exit 1; }

just --justfile press.just --dump --dump-format json | python3 -c '
import json, os, sys
out = sys.argv[1]
recipes = json.load(sys.stdin)["recipes"]
assert recipes, "press.just has no recipes"
for name, recipe in recipes.items():
    lines = []
    for line in recipe["body"]:
        text = ""
        for fragment in line:
            if isinstance(fragment, str):
                text += fragment
            else:
                expr = fragment[0]
                text += "\x27x\x27" if expr[:2] == ["call", "quote"] else "x"
        # A line of a recipe that is not a script may start with @ or -, which just reads.
        lines.append(text.lstrip("@-") if not recipe.get("shebang") else text)
    with open(os.path.join(out, "press.just-" + name + ".sh"), "w") as f:
        f.write("#!/bin/sh\n" + "\n".join(lines) + "\n")
' "$1"

python3 -c '
import os, re, sys
out, path = sys.argv[1], sys.argv[2]
lines = open(path).read().split("\n")
n = 0
i = 0
while i < len(lines):
    m = re.match(r"^(\s*)(?:- )?run: \|\s*$", lines[i])
    i += 1
    if not m:
        continue
    key = len(m.group(1))
    block = []
    while i < len(lines) and (not lines[i].strip() or len(lines[i]) - len(lines[i].lstrip()) > key):
        block.append(lines[i])
        i += 1
    indent = min(len(l) - len(l.lstrip()) for l in block if l.strip())
    n += 1
    with open(os.path.join(out, "action-run-%d.sh" % n), "w") as f:
        f.write("#!/bin/bash\n" + "\n".join(l[indent:] for l in block).rstrip() + "\n")
assert n, path + " has no run: block"
' "$1" .github/actions/typst-toolchain/action.yml
