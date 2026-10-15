# press

A Typst package and build recipes for making documents: page presets, a type and colour
system, ready-made parts, and a build that stamps and checks what it makes. It serves anything
from a one-page information sheet to a conversation piece, a manual or a book, and one PDF
serves both the screen and the printer. Anyone can use it, under the AGPL (see
[Licence](#licence)).

> **Working on this with an agent?** Point it at [`CLAUDE.md`](CLAUDE.md) — install,
> build, authoring vocabulary, how to version the package, and the traps that have
> already bitten once.

## Why this exists

**Every document should start from decisions already made well**, so its author spends the
effort on what it says. The page, the type, the colours and the parts a reader learns to
recognise are decided once, not again in every document.

Typst makes a good document easy to write and hard to keep consistent. Left alone, each one
re-decides its page, its type scale and how a warning looks, and the copies of those decisions
drift apart. press holds them in one place that every repository making documents vendors, so
a new document starts from a ready-made template and ready-made parts, and a fix made for one
document reaches all of them at the next release. It offers rather than governs: a document
takes the parts it wants and composes its own page.

It is more than styling. `just build` stamps each document with when its content last changed
and says what it made, so a printed copy can be checked against the current one. `just check`
catches the font and glyph failures typst lets through without a word. A document is built the
same way on every machine, from fonts that ship with press.

**One output, read anywhere.** A press document is a single PDF that reads on a screen and
prints true, so every part is made for both:

- **Text is real text:** searchable, copyable, and set in vendored fonts, so it renders the
  same on every machine.
- **Links work on both:** they click on screen, and `link-note` footnotes their address for
  paper.
- **A document names itself once:** its title is the PDF's metadata, so a viewer shows it,
  and the template prints it in the header and footer from there.
- **Colour is never the only carrier of meaning,** so a greyscale printer or a colour-blind
  reader loses nothing.
- **Commands are short and unwrapped,** so they copy cleanly from the screen and can be typed
  from paper.
- **Pages keep all ink 0.5in from the edge,** so printing at actual size never clips; on
  screen it is simply margin.
- **Self-contained.** If a fact is needed to act, it is in the document. A runbook kept beside
  the machine it describes is read exactly when that machine is down.

**From a sheet to a book.** The same tokens and parts carry a one-page reference card, a
proposal, a manual and a book. Short documents are best served today. press grows from the
documents that use it: a template or part is added when a real document needs it, and from
the next release every document can use it. Long-form parts (contents, figures, book trim
sizes and facing pages) are among the next.

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

Import it:

```typst
#import "@tylervigario/press:0.2.0": *
```

Build it. A consuming repo carries a one-line `justfile`:

```just
import 'vendor/press/press.just'
```

or, if it already has recipes of its own:

```just
mod press 'vendor/press/press.just'   # -> just press build docs/example.typ
```

Name the time zone `updated()` prints in, once per repo: an IANA name, or `"UTC"` for documents
read across time zones. Unset, it is the zone of whichever machine builds.

```just
export PRESS_TZ := "America/Los_Angeles"
```

and then, identically on Linux and Windows:

```sh
just --list                      # every recipe, self-documenting
just build docs/example.typ      # -> print/docs/example.pdf, and a line saying what it made
just watch docs/example.typ      # a preview on every save -> print/docs/example.watch.pdf
just check docs/example.typ      # audit the PDF for silent font failures
just all                         # every .typ under docs/
just all recipes protocols pcp   # …or under whatever directories you use
just new docs/next-doc
just clean
```

### Requirements

- **typst** 0.14 or newer, **just** 1.55 or newer (`dnf install just`,
  `winget install Casey.Just`) and **`sh`** on `PATH`. On Windows `sh` comes from Git for
  Windows. An older typst or just is refused with a message naming the version it needs.
- `check` also needs **poppler** (`pdffonts`, `pdftotext`, `pdftoppm`) and a **Python**.
  Where `PATH` finds the wrong one, name it: `PRESS_PDFTOTEXT`, `PRESS_PDFFONTS`,
  `PRESS_PDFTOPPM`, `PRESS_PYTHON`.

## Printing

Print at **100% — "Actual size"**, never "Fit to page". The page is exactly US Letter and
keeps all ink at least 0.5in from every edge.

`docs/calibration.typ` prints every ink at every size, every tint, every rule weight and both
solid bands. Print it on the paper and printer you actually use — once at normal quality and
once in economy mode — to find where your hardware gives out before a real document does.

## What lives where

press sets nothing unless a document calls it. A document owns its page and takes whichever
parts serve it.

| | lives in |
|---|---|
| tokens — palette, type scale, faces, page presets | the package |
| vocabulary — `unit`, `chip`, `band-strong`, `decision`, `matrix`, `flow`, `callout`, `code`, `link-note` | the package |
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

Use the face constants — `face-sans`, `face-text`, `face-display`, `face-mono` — never font
names as strings. A missing font only warns, and a missing weight or glyph says nothing at
all; **read [`FONTS.md`](FONTS.md) before using any symbol**, and run `just check`.

## Versioning

A document imports one version, `@tylervigario/press:<version>`, and a released version
never changes. 0.1.0 was released as `@vts/press:0.1.0` and lives on in its tag, v0.1.0;
later releases do not carry it, so a repo moving past it changes the import in the same commit.
A consuming repo moves its submodule only to a release tag, never to a commit on `main`
between releases.

## Licence

Copyright © 2026 Tyler Vigario. **AGPL-3.0-or-later** — see [`LICENSE`](LICENSE). What you
typeset with it is yours: a compiled PDF carries no licence from the tool.

The faces under `fonts/` keep their own terms — Open Sans (Apache-2.0), Liberation
(OFL-1.1-RFN), Montserrat (OFL-1.1). See [`FONTS.md`](FONTS.md).
