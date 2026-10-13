# press

A Typst package and build recipes for documents meant to be printed and read on paper: the
`@vts/press` package, the fonts it depends on, and the conventions that make a printed sheet
scannable. Anyone can use it, under the AGPL (see [Licence](#licence)).

> **Working on this with an agent?** Point it at [`CLAUDE.md`](CLAUDE.md) — install,
> build, authoring vocabulary, how to version the package, and the traps that have
> already bitten once.

## Why this exists

**These documents are read on paper, not on a screen.** A document that lives only in a
repository is least available exactly when the system it describes is down. A printed sheet
has no such dependency, so:

- **Self-contained.** If a fact is needed to act, it is on the sheet.
- **Commands are typed by hand off paper** — short, unwrapped, no fragile quoting.
- **Whitespace is a feature**: it is where the reader writes what actually happened.
- **No copy-paste, no search, no hyperlinks, no colour-only meaning.**

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
#import "@vts/press:0.1.0": *
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
just watch docs/example.typ
just check docs/example.typ      # audit the PDF for silent font failures
just all                         # every .typ under docs/
just all recipes protocols pcp   # …or under whatever directories you use
just new docs/next-doc
just clean
```

### Requirements

- **typst**, **just** (`dnf install just`, `winget install Casey.Just`) and **`sh`** on
  `PATH`. On Windows `sh` comes from Git for Windows.
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

Use the face constants — `face-sans`, `face-text`, `face-display`, `face-mono` — never font
names as strings. A missing font only warns, and a missing weight or glyph says nothing at
all; **read [`FONTS.md`](FONTS.md) before using any symbol**, and run `just check`.

## Versioning

A document imports one version, `@vts/press:<version>`, and a released version never
changes. A consuming repo moves its submodule only to a release tag, never to a commit on
`main` between releases.

## Licence

Copyright © 2026 Tyler Vigario. **AGPL-3.0-or-later** — see [`LICENSE`](LICENSE). What you
typeset with it is yours: a compiled PDF carries no licence from the tool.

The faces under `fonts/` keep their own terms — Open Sans (Apache-2.0), Liberation
(OFL-1.1-RFN), Montserrat (OFL-1.1). See [`FONTS.md`](FONTS.md).
