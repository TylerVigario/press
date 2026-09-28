# press — build recipes for Typst printables.
#
# A consuming repo carries a one-line justfile. If it has no recipes of its
# own:
#
#   import 'vendor/press/press.just'      ->  just build docs/x.typ
#
# If it already has its own — and `build`, `all` and `clean` are names most
# repos will already be using — import HARD-ERRORS on the duplicate. Use a
# module instead, which namespaces them:
#
#   mod press 'vendor/press/press.just'   ->  just press build docs/x.typ
#
# Every recipe carries [no-cd] so both forms behave identically: a module
# would otherwise run with press's own directory as the working directory,
# and every document path would resolve against the wrong tree.
#
# WHY A JUSTFILE, not a wrapper script: one file instead of a POSIX and a
# PowerShell twin that would inevitably drift — the same argument that moved
# the styling into a shared package rather than copy-pasted blocks. `just` is
# identical on every platform: same arguments, same invocation, nothing to
# learn per system. Recipe listing, dependencies and variables come free.
#
# WHY sh EVERYWHERE, with no [windows] attributes: it is `just`'s own default
# and primary path — "just uses `sh` on Windows by default", with PowerShell
# offered only for people who would rather not install `sh`. The maintainer's
# direction for cross-platform recipes (casey/just#531) is to select on shell
# *availability* rather than on OS, which makes OS attributes the workaround
# rather than the destination. On Windows `sh` comes from Git for Windows,
# which is already a prerequisite for cloning this repo at all.
#
# WHAT THIS DOES that a bare `typst compile` will not:
#   · derives the output path, so print/ mirrors the source tree by rule
#     rather than by every author remembering the convention;
#   · creates that directory — typst refuses to write into one that does not
#     exist and fails with a bare "No such file or directory";
#   · carries --root, --package-path, --font-path and --ignore-system-fonts;
#   · stamps the document with when its content last changed (tools/stamp.sh).

# Where press itself lives, resolved from THIS file rather than the consumer's
# root justfile — so press may be vendored at any path and nothing here
# hardcodes one. justfile_directory() would resolve to the importing repo's
# root, which is exactly wrong under `import`.
press_root := source_directory()

# The CONSUMER's root — where print/ belongs and where document paths are
# resolved from. Every recipe cds here first.
#
# [no-cd] is what lets press work under both `import` and `mod`, but it opts out
# of just's own convention that a recipe runs at the project root no matter
# which subdirectory you invoke it from. Left alone, that convention loss is a
# silent-wrong-output bug: `just press build one.typ` from inside recipes/ exits
# 0, prints print/one.pdf, and writes recipes/print/one.pdf — a second output
# tree nested in the source. `clean` then deletes THAT one and reports nothing
# while the real print/ survives untouched.
#
# So: keep [no-cd] to escape press's own directory, then cd deliberately to the
# consumer root. Verified stable in all four cases — mod and import, invoked
# from the root and from a subdirectory. Paths are root-relative, exactly as in
# any ordinary justfile.
root := justfile_directory()

# --ignore-system-fonts removes the MACHINE's fonts, so output cannot vary by
# machine. It does not isolate the vendored faces: typst's own embedded fonts
# stay reachable as per-glyph fallbacks. See FONTS.md.
typst_flags := "--root . --package-path " + quote(press_root / "packages") + \
               " --font-path " + quote(press_root / "fonts") + \
               " --ignore-system-fonts"

[private]
default:
    @just --list --unsorted

# Compile one document → print/<same path>.pdf
#
# The path is relative to the repo root, from whichever directory you invoke it.
#
# Through tools/stamp.sh, which stamps the document with when its content last changed
# (sys.inputs.press-updated, shown by the package's updated()) and keeps that time when a
# rebuild changes nothing on the page. The reasoning is at the top of that file.
[doc("Compile one document -> print/<same path>.pdf")]
[no-cd]
build doc:
    @cd {{ quote(root) }} && sh {{ quote(press_root / "tools" / "stamp.sh") }} {{ quote(doc) }} {{ quote("print" / without_extension(doc) + ".pdf") }} {{ typst_flags }} && echo {{ quote("print" / without_extension(doc) + ".pdf") }}

# Recompile one document on every save
[doc("Recompile one document on every save")]
[no-cd]
watch doc:
    @cd {{ quote(root) }} && mkdir -p {{ quote(parent_directory("print" / doc)) }} && typst watch {{ typst_flags }} {{ quote(doc) }} {{ quote("print" / without_extension(doc) + ".pdf") }}

# Compile every document under the given directories (default docs/)
#
#   just all                              -> docs/
#   just all recipes protocols concerns   -> a repo whose taxonomy IS the point
#
# The default is a convenience, not a required layout. press claims to be
# additive rather than governing, and a build recipe that only walks docs/ would
# quietly make that false — a repo organised by meaning rather than by kind
# should not have to restructure, or write its own `all`, to use this.
#
# Fails loudly on an empty result rather than reporting a green build that
# produced nothing — the state a repo is in before it has adopted any layout,
# and the one where a false success is most expensive. The xargs form (rather
# than a `while read` loop) is what makes a single failing document fail the
# whole recipe: a loop's exit status is only its last iteration's, so doc 1
# could fail and doc 9 succeed and `all` would still exit 0.
#
# It reaches `build` through --justfile rather than as a bare `just build`,
# because under `mod press` the recipe is `press build` and a bare call does not
# resolve — it looks in the CONSUMER's justfile and fails with "does not contain
# recipe `build`". Naming this file explicitly makes `all` behave the same under
# both consumption forms, which is the whole point of the [no-cd] treatment.
#
# --set root is not optional. Under --justfile THIS file becomes the justfile,
# so justfile_directory() would resolve to press's own directory and every
# document path would be looked up there. Passing the consumer root down keeps
# the anchor correct through the recursion.
[doc("Compile every document under the given directories (default docs/)")]
[no-cd]
all +dirs='docs':
    @cd {{ quote(root) }} && for d in {{ dirs }}; do test -d "$d" || { echo "press: no such directory: $d" >&2; exit 1; }; done
    @cd {{ quote(root) }} && test "$(find {{ dirs }} -name '*.typ' | wc -l)" -gt 0 || { echo 'press: no .typ files in: {{ dirs }}' >&2; exit 1; }
    @cd {{ quote(root) }} && find {{ dirs }} -name '*.typ' -print0 | sort -z | xargs -0 -n1 just --justfile {{ quote(press_root / "press.just") }} --set root {{ quote(root) }} build

# Scaffold a new document from the press skeleton
#
# typst init makes a DIRECTORY project. For a single file — which is what most
# documents here are — copy template/main.typ and delete down instead; the
# skeleton's own header says so.
[doc("Scaffold a new document from the press skeleton")]
[no-cd]
new name:
    @cd {{ quote(root) }} && typst init --package-path {{ quote(press_root / "packages") }} @vts/press:0.1.0 {{ quote(name) }}

# Audit a built document for the font failures typst does not report
#
# Two of these checks exist because there are two ways to lose a glyph, and
# neither warns.
#
#   SUBSTITUTED — the codepoint is missing from every vendored face, so typst
#   draws it from one of its OWN embedded fonts. Measured on this package:
#   ✓ ✗ ▸ come from NewCMMath, ⚠ ⚡ ☐ from DejaVuSansMono, ℹ from
#   LibertinusSerif. The page looks almost right and the species is wrong.
#
#   VANISHED — no font anywhere has it, so it is dropped from the page AND from
#   the extracted text. Measured: ⛔ and 📋 disappear outright. This is the worse
#   half: a substitution ships the wrong glyph, a disappearance ships missing
#   content, and a printed sheet cannot be diffed against anything.
#
# The WARNINGS check reads typst's own output. `build` exits 0 on warnings and
# typst has no
# deny-warnings flag, so a warning ships unless something reads it — markdown
# `**bold**` silently renders as nothing, an unknown font family falls back. It
# recompiles and fails on any warning, which is the only enforcement available.
#
# The FONT check catches substitution by listing embedded faces that are not
# vendored here. The GLYPH check catches disappearance by rendering each
# non-ASCII character from the source in ISOLATION and asking whether it survived.
#
# The glyph check probes rather than reading the document's own text layer, because
# that layer lies. In `A ⛔ B 📋 C` with neither symbol drawable, only the FIRST
# unmapped character is dropped from the extracted text; the rest remain in it
# and read back as present. A whole-document scan therefore reports one missing
# glyph when there are five. Isolating one candidate per probe makes each the
# first, and the answer truthful.
#
# The vendored family list is derived by subtracting `typst fonts` without a
# --font-path (typst's own embedded faces) from the same command with one, so
# it stays correct when typst changes what it bundles.
#
# LIMITS, stated because a check trusted past its reach is worse than none:
#   · `#sym.checkmark` and friends carry no source codepoint, so the glyph check
#     cannot see them — the font check still catches the substitution they cause.
#   · Non-ASCII inside a comment is not rendered and will report as vanished.
#     Full-line `//` comments are skipped; trailing ones are not.
#   · A probe asks "can any vendored face draw this", not "does THIS document's
#     face draw it". A glyph present only in the mono face still substitutes in
#     body text — the font check is what catches that.
#   · Space separators and format characters are not probed at all. Nothing is
#     drawn for them, so "did it survive" has no answer, and pdftotext hands
#     back a plain space for U+00A0 — which read as vanished and failed correct
#     documents. A stray invisible character in source is a real fault; it is
#     just not this pass's to report.
#   · Needs poppler — pdffonts, pdftotext AND pdftoppm, all three — and poppler
#     specifically for the first two: Xpdf and mupdf ship programs of those names
#     that disagree about which glyphs a PDF contains, so the recipe asserts the
#     implementation rather than the name. pdftoppm carries no such assertion
#     because nothing else ships one; it is an absence problem, not a wrong-
#     implementation one.
#     That is also why this is a separate recipe rather than part of build:
#     building must not require any of it.
#     Set PRESS_PDFTOTEXT / PRESS_PDFFONTS to point at them directly where PATH
#     cannot be made to resolve poppler first — on Windows it cannot, because
#     Git's sh prepends its own bin directories at startup and the Xpdf copies
#     bundled there win inside every recipe. The assertion still applies to
#     whatever the variables name.
#   · The overlap check sees GLYPHS ONLY. Text printed over a coloured panel, or
#     a rule struck through a line, is invisible to it — those are ink-on-ink,
#     and what would distinguish them is not in the text layer. Nothing cheap
#     covers that case; the printable-area check does not either, because ink in
#     the middle of a page is not its question.
#   · Rotated text is the overlap check's soft spot. Poppler segments rotated
#     glyphs into fragments and reports them as separate lines, which reads as a
#     small phantom overlap — worst measured 0.13pt against a smallest genuine
#     collision of 2.72pt. The 0.5pt floor exists for that gap and nothing else,
#     so a document leaning heavily on rotation deserves a look by eye.
#   · The printable-area check additionally needs a Python and poppler's
#     pdftoppm, and is skipped with a message rather than failing when no
#     interpreter is found. PRESS_PYTHON and PRESS_PDFTOPPM name either
#     directly. The interpreter is found by EXECUTING a candidate, not by
#     resolving a name — Windows ships a zero-byte python3 alias that answers
#     `command -v` and then prints a Store advert, and turning that alias off
#     leaves a working `python` and no `python3`. A name-based guard failed
#     both ways: it ran a stub that could not work, and skipped where a working
#     interpreter was present under the other name.
#
# The PRINTABLE-AREA check verifies that no ink comes within 0.48in of a paper
# edge — the 0.5in safe area the page presets are built around, less a rendering
# tolerance.
#
# The OVERLAP check reports any line of text printed on top of another. It and
# the printable-area check catch LAYOUT faults rather than font ones, and they
# take opposite instruments for a reason worth stating: the printable-area check
# renders the page, because "is there ink near the edge" needs no layering, and
# it must see panels and rules as well as glyphs. The overlap check cannot render,
# because layering is the whole question — two lines drawn on each other and one
# line drawn once are the same pixels. It reads pdftotext's line geometry, where
# that information survives.
#
# The passes themselves live in tools/check.sh. They were inline here until a
# `just` recipe carrying a #!/bin/sh shebang turned out to be translated through
# `cygpath` on Windows, which is absent from PowerShell's PATH even with Git for
# Windows installed — so the only recipe with a shebang was the only recipe that
# would not run from pwsh. A plain recipe handing a file to sh needs no
# translation. It also means the script can be run directly, without just, which
# is how it should be exercised when changing it.
[doc("Audit a built PDF for the font failures typst does not report")]
[no-cd]
check doc:
    @cd {{ quote(root) }} && sh {{ quote(press_root / "tools" / "check.sh") }} {{ quote(doc) }} {{ quote("print" / without_extension(doc) + ".pdf") }} {{ quote(press_root) }} {{ typst_flags }}

# Delete rendered output
#
# Anchored like the rest: without it, running this from a subdirectory deleted a
# stray print/ there and left the real one intact, reporting success either way.
[doc("Delete rendered output")]
[no-cd]
clean:
    @cd {{ quote(root) }} && rm -rf print
