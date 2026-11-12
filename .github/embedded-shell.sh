#!/bin/sh
# embedded-shell.sh — writes out the shell that lives outside a *.sh file, so shellcheck can read
# it: each recipe of press.just, and each run: step of every composite action under
# .github/actions, in whichever form YAML gives it.
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

# Every composite action under .github/actions, found rather than named, as the job finds its
# *.sh files: one added beside the toolchain action is read too.
actions=$(find .github/actions -name 'action.yml' -o -name 'action.yaml' | LC_ALL=C sort)
[ -n "$actions" ] || { echo "embedded-shell.sh: no action under .github/actions" >&2; exit 1; }
# shellcheck disable=SC2086  # each path is one word: no action's path holds a space
python3 -c '
import json, os, re, sys

out, paths = sys.argv[1], sys.argv[2:]
n = 0


def indent(line):
    return len(line) - len(line.lstrip())


def fold(block):
    """A folded block as YAML reads it: lines of one paragraph joined by a space, a blank line
    a line break, and a line indented past the others kept as it is."""
    base = min(indent(l) for l in block if l.strip())
    text, last = "", None
    for l in block:
        if not l.strip():
            text += "\n"
            last = "blank"
            continue
        more = indent(l) > base
        if last == "text" and not more:
            text += " "
        elif last is not None and last != "blank":
            text += "\n"
        text += l[base:] if more else l.strip()
        last = "more" if more else "text"
    return text


for path in paths:
    lines = open(path).read().split("\n")
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)(- )?run:(?:\s+(.*?))?\s*$", lines[i])
        i += 1
        if not m:
            continue
        # The column run: stands in, past the dash of a sequence: what belongs to it is indented
        # further, and the next key of the step stands in it.
        key = len(m.group(1)) + (2 if m.group(2) else 0)
        raw = m.group(3) or ""
        quoted = re.match(r"\"(?:[^\"\\]|\\.)*\"|\x27(?:[^\x27]|\x27\x27)*\x27", raw)
        value = quoted.group(0) if quoted else re.sub(r"(^|\s)#.*$", "", raw).strip()
        follows = []
        while i < len(lines) and (not lines[i].strip() or indent(lines[i]) > key):
            follows.append(lines[i])
            i += 1
        while follows and not follows[-1].strip():
            follows.pop()
        if value[:1] in ("|", ">"):
            # A block: literal, |, kept line for line, or folded, >; its chomping sign is read
            # as clip, which shellcheck cannot tell apart.
            if not any(l.strip() for l in follows):
                continue
            base = min(indent(l) for l in follows if l.strip())
            script = ("\n".join(l[base:] for l in follows) if value[0] == "|"
                      else fold(follows))
        elif value.startswith("\""):
            script = json.loads(value)
        elif value.startswith("\x27"):
            script = value[1:-1].replace("\x27\x27", "\x27")
        else:
            # A plain value, on its line or on the lines after it: YAML joins them by a space.
            script = " ".join([value] + [l.strip() for l in follows if l.strip()]).strip()
        if not script:
            continue
        n += 1
        with open(os.path.join(out, "action-run-%d.sh" % n), "w") as f:
            f.write("#!/bin/bash\n" + script.rstrip() + "\n")
assert n, "no action under .github/actions has a run: step"
' "$1" $actions
