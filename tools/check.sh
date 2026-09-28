#!/bin/sh
# check.sh — audit a built document for the font failures typst does not report.
#
# Invoked by press's `check` recipe, which cds to the consumer root first:
#
#   sh <press_root>/tools/check.sh <doc> <pdf> <press_root> <typst flags...>
#
# Paths are relative to the consumer root, which is why the recipe cds there and
# passes press_root separately — the two are the same directory only when press
# is being used on itself.
#
# It lives here rather than inline in press.just because a `just` recipe carrying
# a #!/bin/sh shebang is translated through `cygpath` on Windows, and cygpath is
# absent from PowerShell's PATH even where Git for Windows is installed — so the
# only recipe with a shebang was the only recipe that would not run from pwsh.
# A plain recipe handing a file to sh needs no translation and behaves the same
# from either shell.
#
# The rationale for what each pass does, and the limits of each, is in press.just
# above the recipe. This file is the mechanism; that comment is the argument.
set -eu

src=$1
pdf=$2
press_root=$3
shift 3
# What remains in "$@" is typst_flags, already shell-quoted by just, so it
# re-parses into separate arguments here. Passing it through rather than
# rebuilding it keeps this file from drifting away from build and watch.

test -f "$pdf" || { echo "press: not built yet — run build first: $pdf" >&2; exit 1; }
# The glyph check needs a grep that speaks PCRE, honours the (*UTF) verb, and knows
# \p{...} properties. Assert it here rather than relying on the pipeline to complain:
# $? in `a | b | sort` belongs to sort, so a grep that rejects any of the three leaves
# the character list empty and the check skips itself while the recipe goes on to report
# the document clean. Probing once, up front, is the difference between an unmet
# dependency and a check that quietly does nothing.
#
# The probe is the construct itself, not a proxy for it: a literal U+00A0 must match
# the same class the extraction filters on. Without (*UTF) that is two bytes and the
# anchored single-character class cannot match; without properties grep errors outright.
# One assertion, and it fails for either missing piece.
printf '\302\240\n' | grep -qP '(*UTF)^[\p{Z}\p{Cf}]$' 2>/dev/null \
    || { echo 'press: check needs a grep whose PCRE supports the (*UTF) verb and \p{...} properties' >&2; exit 1; }
# Poppler specifically, not merely a program answering to that name.
#
# pdftotext and pdffonts are also shipped by Xpdf and mupdf, and they do not agree.
# Measured over one document: Xpdf's default output encoding is Latin-1, which loses
# every non-ASCII character — so every glyph looks missing, and the glyph check
# accuses a correct document sixteen times over. mupdf's copy reports a different
# set again. The extractor is not an implementation detail here; it is the
# instrument the verdict is read off, and three instruments give three verdicts
# on identical input.
#
# This matters most where it is least visible: Git for Windows bundles Xpdf's
# pdftotext in mingw64/bin and Git Bash puts that ahead of a system poppler, so a
# Windows contributor and CI silently run different checks on the same commit.
#
# -v is the discriminator. Poppler prints "The Poppler Developers"; Xpdf prints
# "[www.xpdfreader.com]". Both are checked because a PATH can resolve them to
# different projects.
#
# PRESS_PDFTOTEXT and PRESS_PDFFONTS exist because on Windows PATH is not the
# user's to order. Git for Windows' sh prepends its own /mingw64/bin and
# /usr/bin at startup, so the Xpdf binaries it bundles win inside every recipe
# no matter what PowerShell or a .bashrc resolves — a Windows contributor has
# no reachable lever. Naming the executable directly is that lever, and it is
# press-scoped: nothing else on the machine reads these names, so unlike
# renaming the bundled binaries it shifts no other tool's dependency.
#
# The assertion is unchanged either way. Being pointable does not mean being
# trusted; whatever it is aimed at still has to say poppler.
PDFTOTEXT=${PRESS_PDFTOTEXT:-pdftotext}
PDFFONTS=${PRESS_PDFFONTS:-pdffonts}
for spec in "PRESS_PDFTOTEXT $PDFTOTEXT" "PRESS_PDFFONTS $PDFFONTS"; do
    var=${spec%% *}; tool=${spec#* }
    command -v "$tool" >/dev/null 2>&1 \
        || { echo "press: check needs poppler; $tool not found" >&2
             echo "       set $var to poppler's binary if it is not on PATH" >&2
             exit 1; }
    "$tool" -v 2>&1 | grep -qi poppler \
        || { echo "press: $tool is not poppler's —" >&2
             "$tool" -v 2>&1 | head -1 | sed 's/^/  /' >&2
             echo "       extractors disagree about which glyphs a PDF contains, so the" >&2
             echo "       glyph check is only meaningful against poppler." >&2
             echo "       Put it first on PATH, or set $var to it directly." >&2
             exit 1; }
done
allow=$(ls "$press_root/fonts" | sed 's/-[A-Za-z]*\.[to]tf$//;s/\.[to]tf$//' | sort -u | paste -sd'|')
rc=0
# Recompile FIRST, and keep the compiler's own status.
#
# Every check below reads $pdf, so the recompile has to happen before any of them or
# they audit whatever build last left there. Ordering it after the printable-area
# check meant that one alone judged a different artifact than the font checks: a
# source edited to paint ink 0.05in from the edge was reported clean, because the
# margins were measured on the previous build and the fresh PDF was written after.
# That is the check whose whole justification is that the fault is invisible until
# it is on paper.
#
# And the status must come from typst, not from the grep reading its output. Piping
# into grep hands $? to grep, so a source that did not compile at all left the old
# PDF in place, produced error: lines that no warning: filter matched, and every
# pass then passed the stale artifact — `build` failing while `check` said clean.
#
# Through stamp.sh, as `build` does: a bare typst compile here would overwrite the
# stamped PDF with an unstamped one, and every check would wipe the edition off the page.
out=$(sh "$press_root/tools/stamp.sh" "$src" "$pdf" "$@" 2>&1) || {
    echo "press: $src does not compile —" >&2
    printf '%s\n' "$out" | sed 's/^/  /' >&2
    exit 1
}
# The PRINTABLE-AREA check. A document can overflow the unprintable band
# silently: typst has no concept of it, so the failure appears on paper and
# nowhere else. Skipped rather than fatal where no interpreter is present,
# because font checking is worth having on its own and press must stay usable on
# a box that has poppler but no python at all.
#
# `command -v python3` was the guard and it FAILED BOTH WAYS on Windows.
#
#   Present but not real: the stock Windows App Execution Alias puts a zero-byte
#   python3 on PATH that prints "Python was not found" and exits 49. command -v
#   said yes, the printable-area check ran, and check exited 1 having printed
#   nothing but a Microsoft Store advert.
#
#   Real but not named python3: disabling that alias — which uv's own setup
#   recommends — leaves a working `python` and no `python3` at all, so the check
#   silently skipped forever. Measured on a host where it hid a genuine 0.32in
#   clipping fault in a document whose entire purpose was to be printed.
#
# So probe by EXECUTING a candidate rather than by resolving its name, and accept
# `python`, which is what a Windows install is actually called. An interpreter
# that cannot run `pass` is not an interpreter, whatever PATH says about it.
# PRESS_PYTHON is tested SEPARATELY and quoted, never as a word in the candidate
# list. Unquoted it word-splits, and the likeliest Windows value is exactly the
# case that breaks: C:\Program Files\Python312\python.exe becomes "C:\Program" and
# "Files\Python312\python.exe", neither of which runs.
#
# An override that is set but cannot run says so rather than falling through in
# silence -- that is a typo the operator wants to hear about -- but it still falls
# back, because this pass is skippable and a bad override should not take out the
# font checks with it.
PY=
if [ -n "${PRESS_PYTHON:-}" ]; then
    if "$PRESS_PYTHON" -c 'pass' >/dev/null 2>&1; then
        PY=$PRESS_PYTHON
    else
        echo "press: PRESS_PYTHON is set but will not run: $PRESS_PYTHON" >&2
        echo "       falling back to python3 / python" >&2
    fi
fi
if [ -z "$PY" ]; then
    for cand in python3 python; do
        if "$cand" -c 'pass' >/dev/null 2>&1; then PY=$cand; break; fi
    done
fi
if [ -n "$PY" ]; then
    PRESS_PDFTOPPM="${PRESS_PDFTOPPM:-pdftoppm}" \
        "$PY" "$press_root/tools/ink-margin.py" "$pdf" 0.48 || rc=1
else
    echo "press: skipping the printable-area check (no working python found)" >&2
    echo "       set PRESS_PYTHON to one if it is not on PATH as python3 or python" >&2
fi
# The OVERLAP check — text printed on top of text. A document can collide with
# itself, clear every other check, and reach paper: typst emits no warning
# because nothing is wrong, the document is valid and simply renders on top of
# itself. It was found in practice by people looking at rendered pages,
# repeatedly, which is what this removes.
#
# Shares the printable-area check's interpreter and skip behaviour, and the same
# reasoning: a box with poppler and no python still gets the font checks. It does
# NOT share its instrument — see the module docstring for why the raster cannot
# answer this and pdftotext can.
if [ -n "$PY" ]; then
    PRESS_PDFTOTEXT="$PDFTOTEXT" "$PY" "$press_root/tools/line-overlap.py" "$pdf" || rc=1
else
    echo "press: skipping the line-overlap check (no working python found)" >&2
fi
warns=$(printf '%s\n' "$out" | grep '^warning:' || true)
if [ -n "$warns" ]; then
    echo "press: $src compiles with warnings — typst exits 0 on these and there is no" >&2
    echo "       deny-warnings flag, so they ship unless something reads them:" >&2
    echo "$warns" | sed 's/^/  /' >&2
    rc=1
fi
leaks=$("$PDFFONTS" "$pdf" | tail -n +3 | awk '{print $1}' | sed 's/^[A-Z]*+//' | grep -vE "^($allow)" || true)
if [ -n "$leaks" ]; then
    echo "press: $pdf draws from fonts that are NOT vendored here —" >&2
    echo "$leaks" | sort -u | sed 's/^/  /' >&2
    rc=1
fi
# (*UTF) forces PCRE to match characters rather than bytes. Without it the class
# is byte-oriented under a non-UTF-8 locale, so every multi-byte character is split
# into its bytes and each byte is probed as though it were a character — none of
# which render, so a clean document reports one false missing glyph per byte.
#
# The verb rather than LC_ALL=C.UTF-8 on purpose: the locale must exist to take
# effect, macOS has no C.UTF-8, and glibc falls back to C *silently* when a locale
# is missing. That reintroduces the bug while the check reports success, which is
# the one failure mode this recipe exists to prevent. The verb needs nothing from
# the environment; the guard above is what makes its absence loud.
#
# `|| true` stays: grep exits 1 on a document with no non-ASCII characters at all,
# which is a clean result, not an error. Exit 2 is what would matter here, and the
# guard has already ruled out the only way to provoke it.
#
# \p{Z} and \p{Cf} are dropped because only a character that HAS a glyph can be
# missing one. Space separators and format characters are absence by design, and
# pdftotext gives back a plain space for U+00A0, so probing them fails a document
# that is correct. Stray invisible characters in source are a real concern and a
# different one; the check that owns that concern should own it.
chars=$(grep -v '^[[:space:]]*//' "$src" \
        | grep -oP '(*UTF)[^\x00-\x7F]' \
        | grep -vP '(*UTF)^[\p{Z}\p{Cf}]$' \
        | sort -u || true)
if [ -n "$chars" ]; then
    fontdir="$press_root/fonts"
    fams=$(comm -13 "$(typst fonts --ignore-system-fonts | sort > /tmp/press-embedded.$$; echo /tmp/press-embedded.$$)" \
                    "$(typst fonts --font-path "$fontdir" --ignore-system-fonts | sort > /tmp/press-all.$$; echo /tmp/press-all.$$)" \
           | sed 's/.*/"&"/' | paste -sd,)
    rm -f /tmp/press-embedded.$$ /tmp/press-all.$$
    # Templated on purpose: a bare `mktemp -d` is a GNU extension and BSD/macOS
    # rejects it with "too few X's in template".
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/press.XXXXXX")
    trap 'rm -rf "$tmp"' EXIT INT TERM
    for ch in $chars; do
        printf '#set page(width: 6cm, height: 2cm)\n#set text(font: (%s))\nX%sX\n' "$fams" "$ch" > "$tmp/probe.typ"
        typst compile --root "$tmp" --font-path "$fontdir" --ignore-system-fonts "$tmp/probe.typ" "$tmp/probe.pdf" 2>/dev/null || true
        if ! "$PDFTOTEXT" "$tmp/probe.pdf" - 2>/dev/null | grep -qF "$ch"; then
            echo "press: $pdf is MISSING a character present in the source: $ch" >&2
            rc=1
        fi
    done
fi
if [ "$rc" -eq 0 ]; then echo "press: $pdf clean"; fi
exit "$rc"
