# press

The house apparatus for Vigario Technology Solutions printed documents: the
`@vts/press` Typst package, the fonts it depends on, and the conventions that make a
document scannable.

> **Working on this with an agent?** Point it at [`CLAUDE.md`](CLAUDE.md) — install,
> build, authoring vocabulary, how to version the package, and the traps that have
> already bitten once.

## Why this exists

**These documents are read on paper, not on a screen.**

A document that lives only in a repository has a circular dependency: reading it requires the
system it describes to be working, reachable, and logged into. When the controller is down,
when the host is unreachable, when the fleet is logged out — the document is least available
exactly when it is most needed. A printed sheet has no such dependency.

That is the justification for this repo. The typography is downstream of it, and every design
decision here answers to it:

- **Self-contained.** No cross-reference carries load, no link does work, no step assumes a
  browser or a shell is at hand. If a fact is needed to act, it is on the sheet.
- **The act layer is the first section, and it runs as long as the work does.** Keeping it
  to one page is a goal worth aiming at — anything split across a page turn gets read half
  — but it is a goal, not a budget. **Content prevails**, exactly as in convention 6 below.
  A step shortened to save a line is a step that gets typed wrong at 2am, which costs more
  than a page turn ever did.
- **Commands are typed by hand off paper** — short, unwrapped, no fragile quoting. A plainer
  command carrying the same information beats a precise one that wraps mid-token.
- **Whitespace is a feature**, not a gap to fill: it is where the reader writes what actually
  happened.
- **No copy-paste, no search, no hyperlinks, no colour-only meaning.** Anything that only
  works on a screen is decoration on paper.

This applies to *every* document, not the obviously urgent ones. During an incident a service
inventory, a storage layout or a restore procedure gets consumed more than a runbook does.

**It is a current constraint, not a permanent law.** If public consumption becomes a concern
and digital files prevail, this gets revisited with a different system. That time has not come.

Consumed as a **git submodule**, so one source of truth serves every repository while each
one pins the version it uses.

## Using it

Add it to a project:

```sh
git submodule add https://github.com/TylerVigario/press vendor/press
```

Clone a project that already uses it:

```sh
git clone --recurse-submodules <project>
# or, after a plain clone:
git submodule update --init --recursive
```

`git config --global submodule.recurse true` makes `pull`, `checkout` and `switch` recurse
from then on. It does **not** cover `clone` — that one command is the whole of the friction.

Import it:

```typst
#import "@vts/press:0.1.0": *
```

Build it. A consuming repo carries a one-line `justfile`:

```just
import 'vendor/press/press.just'
```

and then, identically on Linux and Windows:

```sh
just --list                      # every recipe, self-documenting
just build docs/example.typ      # -> print/docs/example.pdf
just watch docs/example.typ
just check docs/example.typ      # audit the PDF for silent font failures
just all                         # every .typ under docs/
just all recipes protocols pcp   # …or under whatever directories you use
just new docs/next-doc
just clean
```

`print/` mirrors the source tree by rule rather than by everyone remembering the
convention, and the recipe creates the directory — `typst` will not, and fails with a bare
"No such file or directory".

Paths are relative to the repo root from whichever subdirectory you invoke, as in any
ordinary justfile. `docs/` is `all`'s default argument, not a required layout.

If the consuming repo already has recipes of its own, use a module instead — `import`
hard-errors on a duplicate name, and `build`, `all` and `clean` are names many repos
already use:

```just
mod press 'vendor/press/press.just'   # -> just press build docs/example.typ
```

There is no wrapper script and no PowerShell twin. One file, one set of arguments, nothing
to learn per system.

### Requirements

- **typst** on `PATH`.
- **just** on `PATH` — a single static binary (`dnf install just`, `winget install Casey.Just`).
- **`sh` on `PATH`.** This is `just`'s own default and primary path: *"just uses `sh` on
  Windows by default"*, with PowerShell offered only for people who would rather not install
  it. On Windows `sh` comes from Git for Windows, already a prerequisite for cloning this
  repo. Recipes therefore carry no `[windows]`/`[unix]` attributes — the maintainer's
  direction for cross-platform recipes (casey/just#531) is to select on shell *availability*
  rather than OS, which makes those attributes a workaround rather than the destination.

Underneath, `build` compiles like this, run from the repo root — and adds a stamp of when the
document's content last changed (`tools/stamp.sh`; a document shows it with `updated()`),
keeping the previous time when a rebuild changes nothing on the page. By hand, unstamped:

```sh
mkdir -p print/docs
typst compile --root . \
  --package-path vendor/press/packages \
  --font-path vendor/press/fonts --ignore-system-fonts \
  docs/example.typ print/docs/example.pdf
```

`check` additionally needs **poppler** — `pdffonts`, `pdftotext` and `pdftoppm`, all
three — plus a **Python** for the printable-area and overlap checks. It is deliberately
not part of `build`, so building never depends on any of it.

#### On Windows, `python3` lies in both directions

**A Windows host can have a perfectly good Python and still fail this check, and it
can also appear to have one when it has none.** Both states are caused by the same
thing — the **App Execution Alias** — and a check that resolves the *name* `python3`
cannot tell either of them from a working interpreter.

| State | `command -v python3` | What actually happens |
|---|---|---|
| Alias on, no Store Python (Windows default) | **succeeds** | A zero-byte stub prints `Python was not found`, exits 49 |
| Alias off (uv's setup recommends this) | **fails** | A working `python` is right there under the other name |
| Store Python installed | succeeds | Genuinely works |

The middle row is the dangerous one. The checks that need an interpreter —
printable-area and overlap — are skipped, and while the skip is announced on
stderr the **verdict is still clean**. A green verdict is what gets believed.
That is not hypothetical: it hid a real 0.32in clipping fault in a document whose
entire purpose was to be printed.

The first row has already misdirected a change. `server-admin#82` recorded
`Python was not found` in its verification notes, concluded *"so poppler does not
resolve"* — the wrong subsystem entirely — and merged it as environmental.

press therefore probes by **executing** a candidate rather than resolving a name, and
accepts `python` as well as `python3`. Where neither is on `PATH`, or the wrong one
is found first, name the executable directly:

```sh
PRESS_PYTHON=/path/to/python  PRESS_PDFTOPPM=/path/to/pdftoppm  just check docs/x.typ
```

Same reasoning as `PRESS_PDFTOTEXT` and `PRESS_PDFFONTS`: on Windows `PATH` is not
the contributor's to order, so the lever has to be the executable's name.

## Printing

Print at **100% — "Actual size"**, never "Fit to page". The page is exactly US Letter, so
no scaling is wanted, and fitting shrinks the sheet and undoes the type scale. The presets
keep all ink at least 0.5in from every edge, which clears the unprintable band consumer
printers enforce in hardware and usually expose no setting for.

`docs/calibration.typ` in this repo prints every ink at every size with its measured
contrast, every tint, every rule weight and both solid bands, over two duplexed pages.
Print it on the paper and printer you actually use — once at normal quality and once in
economy mode — to find where your hardware gives out before a real document does.

Start a new document from the skeleton:

```sh
typst init --package-path vendor/press/packages @vts/press:0.1.0 <name>
```

That **copies** the skeleton rather than importing it. Composition belongs to the document;
only the vocabulary is shared.

## What this is, and is not

`press` is **additive, not governing**. Nothing it exports takes effect unless a document
calls it: it sets no page and installs no show rule *of its own accord*, and assumes no
layout. A document owns its own page and takes whichever parts serve it.

That inversion is the whole design. A template that *owns* the page forces every document
with real layout needs to escape the system — which is exactly what happened to the
markdown-to-PDF pipeline this replaces.

**"Not governing" limits what press ENFORCES, never what it may OFFER.** The page presets
are the shape of it:

```typst
#set page(..dense)
```

press supplies the preset; the document chooses to spread it, and a document that wants
different margins writes its own and is not deviating. A styling helper works the same
way, including one a document installs as its own show rule — the document opted in, so
nothing was enforced. Treating styling as out of scope leaves every document inventing its
own, which is the copy-paste drift `press` exists to end, one level down.

**press is a helper, not a governor**, so nothing must clear a threshold before it may be
offered here. Documents vary enormously — a printed runbook, a service inventory and an
ATS résumé share fonts and little else — and nothing can decide in advance what will prove
useful to them. A helper nobody calls costs a document nothing.

| | lives in |
|---|---|
| tokens — palette, type scale, faces, page presets | the package |
| vocabulary — `unit`, `chip`, `band-strong`, `decision`, `matrix`, `flow`, `callout`, `code` | the package |
| composition — section order, page choice, diagrams, depth layering | the document |
| fonts | `fonts/`, a build input rather than styling API |

## Conventions

Tokens alone do not make a document readable. These do:

1. **Meat first.** Whatever must be acted on goes at the top. Attention is spent before it is
   earned back.
2. **One idea per unit, opened by a bold lead.** That lead is the highlight, pre-made.
3. **Units are self-contained.** Sections get read out of order and returned to weeks later.
4. **Bands carry a role** — decide / design / reference — so skipping is deliberate.
5. **Colour is state, never decoration**, and it gets a legend.
6. **No length cap.** If a unit needs depth, give it depth, or push the depth to a second
   layer. Never delete content to fit a layout — if it does not fit, *the layout* changes.

## Fonts

Faces are vendored, and the package exports them as **constants** (`face-sans`, `face-text`,
`face-display`, `face-mono`) rather than callers writing strings. Each constant is a
**stack** — the intended face, then a vendored fallback.

Typst does not perform metric substitution the way fontconfig does:

```
fc-match Arial          -> Liberation Sans   (fontconfig substitutes)
typst, system fonts on  -> warning: unknown font family: arial
```

A missing *family* is only a warning, and Typst has no deny-warnings flag, so a typo
silently ships. Constants turn that into an unknown-variable error, which does fail the
build. A missing *weight* or *glyph* is quieter still — neither says anything at all, and
`--ignore-system-fonts` does not protect you because Typst's own embedded fonts remain
reachable. **[`FONTS.md`](FONTS.md) documents all three levels and is required reading
before adopting any symbol vocabulary**; `just check` is what catches them.

Licences permit redistribution: Open Sans (Apache-2.0), Liberation (OFL-1.1-RFN),
Montserrat (OFL-1.1). The weights and styles vendored are listed in `FONTS.md`, and that
table is a constraint rather than an inventory — asking for a weight that is not there
fails silently.

## Versioning

Versions live side by side under `packages/vts/press/<version>/`, so a document keeps
compiling against the version it was written for. **Released versions are immutable** — a
change adds a directory rather than editing one, because consumers pin an exact version and
a silent edit underneath them is the failure packaging exists to prevent. Until a version's
first release, its directory takes additions.

## Why not Typst Universe

Universe publishes into the `@preview` namespace, which would cost the `@vts` identity, and
its naming rules exclude "obvious or canonical" names — `press` is squarely one. Publication
is also gated on a maintainer merging a pull request, and a registry package cannot be edited
locally. A submodule keeps the namespace, instant iteration, and local editability.

## Licence

Copyright © 2026 Tyler Vigario. **AGPL-3.0-or-later** — see [`LICENSE`](LICENSE).

The bargain is reciprocal: build on press and pass on the freedoms you received. Nobody
gets to wall off source they did not write.

- **What you typeset is yours.** A compiled PDF is program output, and output carries no
  licence from the tool that produced it. Nothing here claims any right in your content,
  and no licence could — copyleft governs the terms a work travels under, never its
  ownership.
- **Source that imports press** forms a combined work with it. Convey that source and it
  travels under AGPL-compatible terms. You keep every bit of your copyright; whoever
  receives it gets the freedoms you got.
- **Modified press is AGPL**, without qualification. Charge for it if you like — §4 has
  always permitted that — but it stays open, and that is the whole point.

The faces vendored under `fonts/` are **third-party and not covered by the above**. They
keep their own terms — Open Sans (Apache-2.0), Liberation (OFL-1.1-RFN), Montserrat
(OFL-1.1) — each of which permits redistribution and embedding in documents. See
[`FONTS.md`](FONTS.md).
