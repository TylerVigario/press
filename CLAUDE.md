# press — instructions for an agent

`press` is a Typst package plus build recipes that repos vendor as a submodule. It gives
a repo a **shared vocabulary and a reproducible build**, and nothing else — the page layout
stays in the document.

Read this whole file before changing anything. Every trap listed has already happened.

---

## The constraint everything follows from

**These documents are read as printed sheets, off-system** — when the system they describe
may be down. Apply this to every document:

- **Self-contained.** No "see the other doc" carrying load, no link doing work, no step that
  assumes a shell or browser. If a fact is needed to act, it is on the sheet.
- **The act layer is the first section, and it runs as long as the work does.** One page is
  a goal, not a budget: when the two conflict, content wins.
- **Commands are typed by hand off paper.** Short, unwrapped, no fragile quoting. A plainer
  command carrying the same information beats a precise one that wraps mid-token — and say
  so when you make that trade.
- **Whitespace on the act page is a feature.** It is where the reader writes what happened.
- **No colour-only meaning, no search, no copy-paste.**

---

## Installing press into a repo

```sh
git submodule add https://github.com/TylerVigario/press vendor/press
git -C vendor/press checkout v<version>   # a release tag, never a commit on main
git add vendor/press
```

Then one line in the consuming repo's `justfile`:

| Situation | Line | Invocation |
|---|---|---|
| No justfile yet, or no name clashes | `import 'vendor/press/press.just'` | `just build docs/x.typ` |
| Repo already has its own recipes | `mod press 'vendor/press/press.just'` | `just press build docs/x.typ` |

`import` **hard-errors** on a duplicate recipe name, and press exports `build`, `watch`,
`check`, `all`, `new` and `clean`. When unsure, use `mod`. A repo with its own `all` must use
`mod`.

After a plain `git clone` of a consuming repo, `vendor/press` is **empty** (`clone` ignores
`submodule.recurse`) and the symptom is `justfile does not exist`. Say this in the consuming
repo's own docs:

```sh
git submodule update --init --recursive
```

---

## Building

```sh
just build docs/services.typ     # -> print/docs/services.pdf, and a line saying what it made
just watch docs/services.typ     # recompile on save
just all                         # every .typ under docs/ (fails if there are none)
just all recipes protocols pcp   # any directories — docs/ is a default, not a layout
just check docs/services.typ     # audit the built PDF
just new docs/thing              # -> docs/thing/main.typ, from the skeleton
just clean                       # delete print/
```

**Requirements:** `typst` 0.14 or newer, `just` 1.55 or newer and `sh` on PATH; on Windows
`sh` comes from Git for Windows. `press.just` refuses an older typst or just, naming the
version it needs; raising either floor is a deliberate edit there. `check` also needs poppler
(`pdffonts`, `pdftotext`, `pdftoppm`) and a Python. Where PATH finds the wrong one, name it
with `PRESS_PDFTOTEXT`, `PRESS_PDFFONTS`, `PRESS_PDFTOPPM` or `PRESS_PYTHON`. On Windows,
Git's `sh` puts its bundled Xpdf `pdftotext` first inside every recipe, so set
`PRESS_PDFTOTEXT` there; `check` refuses anything that is not poppler.

**Paths are relative to the repo root**, from whichever directory you invoke.

**Page orientation and size are the document's.** The presets are portrait US Letter;
landscape is `#set page(..dense, flipped: true)`.

**Print at 100% — "Actual size", never "Fit to page".** The presets keep all ink at least
0.5in from every edge, which is what clears a printer's unprintable band. A document that
overrides `margin`, or places content absolutely (cetz canvases), can break that — `check`
measures it.

**`build` stamps each document with when its content last changed**, as
`sys.inputs.press-updated`; `updated()` shows it, in the footer so every page carries it. A
rebuild that changes nothing on the page keeps the old time. A new typst or new fonts can
re-stamp an unchanged page. `watch` and a bare `typst compile` pass no stamp, and
`updated()` says so.

**The stamp prints in `PRESS_TZ`**, which the consuming repo exports from its justfile:
`export PRESS_TZ := "America/Los_Angeles"`, or `"UTC"` for documents read across time zones.
Every machine then prints the same text, so an unchanged page stays unchanged wherever it is
built. Unset, it is the building machine's zone, and a build under another zone re-stamps.
A name not in the machine's tz database fails the build rather than printing UTC mislabelled.

**`build` then prints one line per document** — new, changed or unchanged, pages, words
(with poppler), size and the stamp — and `all` ends with a count.

**Run `check` before calling a document done.** Neither `build` nor `all` runs it.

| check | asks |
|---|---|
| **warnings** | did typst warn — it exits 0 on warnings and has no deny-warnings flag |
| **font** | does the PDF draw from a face not vendored here (a *substitution*) |
| **glyph** | did every non-ASCII character in the source survive to the page (a *disappearance*) |
| **printable-area** | is any ink within 0.48in of a paper edge |
| **overlap** | is any line of text printed on top of another |

Printable-area and overlap need Python; without it they are **skipped with a message and the
verdict still says clean** — read the output, not just the verdict. Overlap sees glyphs only:
text over a panel is outside its reach. The LIMITS comment on `check` in `press.just` lists
the rest.

---

## Writing a document

**Import the vocabulary, then compose the page yourself:**

```typ
#import "@vts/press:0.1.0": *
```

`just new docs/thing` scaffolds a skeleton at `docs/thing/main.typ`, built with
`just build docs/thing/main.typ`. The name is a directory, so it takes no `.typ`. **Copy the
skeleton, do not import it** — composition belongs to the document.

**Show rules are the document's to install.** Nothing takes effect until the document asks.
A document with commands in it wants both:

```typ
#show raw: set text(font: face-mono, size: sz.micro)
#show raw.where(block: true): code
```

### The six conventions

1. **Meat first.** Whatever the reader must act on goes at the top — never make them read
   design detail to reach a decision.
2. **One idea per unit, opened by a bold lead.** The lead is the highlight, pre-made.
3. **Units are self-contained.** Nothing may assume the unit above it was read.
4. **Bands carry a role** — decide / design / reference — so skipping is deliberate.
5. **Colour is state, never decoration, and it gets a legend.**
6. **No length cap.** If a unit needs depth, give it depth or push it to a second layer —
   never delete it to fit a layout. If it does not fit, *the layout* changes.

From 1 and 6: **the act layer comes first, the depth layer after a `#pagebreak()`**, with an
italic line saying nothing past it is needed to act. The split is by role, not page number:
an act layer that honestly needs two pages gets two. Reference documents get the same
treatment.

### When the conventions do not apply

**The conventions are for a sheet read by a human.** A document whose first reader is a
machine — an ATS résumé, parsed with `pdftotext -layout` — must stay single-column:
`unit`, `chip` and two-column grids break its reading order. It takes press's **tokens and
fonts** and none of its layout conventions, and that is correct. Before "improving" a
document into press's style, establish who reads it first; if a parser, leave it
single-column and say so in a comment at the top of the file.

### Vocabulary

Tone is a string: `"note"` (slate) · `"ok"` (green) · `"warn"` (amber) · `"bad"` (red).

| Call | For |
|---|---|
| `unit(label, tone, lead, body, caps:, breakable: false)` | The workhorse. One idea: label, bold lead, body. |
| `units(..items, pack: "stacks", gutter:, spacing:)` | Lays out a group of units. `"stacks"`: two columns balanced by measured height, nothing padded. `"grid"`: row-major, rows aligned — when the pairing means something. `"single"`: one column. |
| `band-strong(title, role, color:, caps:)` | Section header carrying its role. |
| `band(label, color: slate)` | Lighter section header. |
| `titlebar(title, meta, color:, face:, size:)` | Document head with right-aligned meta. |
| `eyebrow(body, color:, caps:)` | Small tracked-out uppercase label. |
| `chip(label, tone)` | Inline state pill — build legends from these. |
| `callout(body, tone: "note", label: none, size:)` | Aside that must not be missed. |
| `panel(body, label: none, color: slate)` | Boxed block, no tone semantics. |
| `code(body, breakable: false)` | Code-block treatment. **The document installs it**: `#show raw.where(block: true): code`. |
| `item(n, title, body, color:, size:)` | Numbered step. |
| `matrix(head, ..rows)` | Two-column comparison table. |
| `sheet(cols, head, ..rows, size:)` | Wide data table — any column count, zebra rows, header repeats across pages. |
| `flow(..steps)` | Left-to-right stage sequence. |
| `decision(n, q, note, color: bad)` / `dbadge(n, color:)` | Open question needing an answer. |
| `seedepth(label)` | Pointer from the act layer to the depth layer. |
| `stamp(body)` | Closing line — provenance, or "the host is right". |
| `updated()` | When the content last changed, as `build` stamps it. For the footer. |

**Tokens.** Colours `ink`, `ink-soft`, `ink-faint`, `rule-hair`, `rule-mid`,
`paper-tint`, `slate`, `slate-tint`, `steel`, and `ok`/`warn`/`bad` each with a `-tint`.
Faces `face-text` (Open Sans), `face-display` (Montserrat), `face-sans` (Liberation
Sans), `face-mono` (Liberation Mono). Sizes `sz.micro` 8.6 · `fine` 9.4 · `small` 10.2 ·
`body` 11 · `lead` 12.5 · `head` 14.5 · `title` 21 · `hero` 28. Page presets `dense`,
`reading`, `card` — spread with `#set page(..card)`.

**When the vocabulary does not fit, build it in the document.** That is correct. A helper
may also be proposed for press; nothing has to clear a bar first.

---

## Changing press itself

**Every change is a pull request.** `main` takes no direct pushes. PRs squash-merge with the
PR title as the commit, so the title must be a conventional commit (CI validates it); the
type decides the next version. CI also builds and checks `docs/`, and runs shellcheck,
markdownlint (lines ≤ 100), actionlint, a JSON parse, an invisible-character scan and
CodeQL. The tools CI installs are pinned by hand, with digests, and Dependabot cannot see
them; the weekly Pins workflow opens an issue for each release a pin is behind
(`sh .github/pins.sh` shows the same comparison).

**Never edit a released version directory.** `v<version>` releases
`packages/vts/press/<version>/`, and CI's *Released versions are unchanged* fails any PR that
edits or removes it. For a change to the package, copy the newest version directory to the
next version, set `version` in its `typst.toml`, and edit there. Name it for the version the
commits will derive — ask `cog bump --auto --dry-run` or a dry run of the Release workflow;
the release refuses a name that disagrees. Until a version's first release its directory
takes additions.

**Releasing is one run of the Release workflow, dry run first.** It derives the version from
the commits, gates on CI, writes `CHANGELOG.md` in a `release:` commit by the
`vigario-press-release` App (with the version directory, when a tooling-only release needs
one), and publishes the GitHub release, which creates the tag. Never tag by hand. If it fails
after the `release:` commit has landed, start a new run rather than re-running the failed one:
a re-run checks out the old commit and the forge refuses its commit.
`CHANGELOG.md` is generated except for its hand-written first release, "Initial release.",
which `.github/write-changelog.sh` keeps (until cocogitto/cocogitto#580 is fixed).

**`just new` scaffolds from the version named in `press.just`** (`@vts/press:0.1.0` today).
Move it when a new version is released.

**Editing press from inside a consuming repo.** A submodule is a **detached HEAD**; a commit
made there is lost. Branch, open a PR, then put the submodule back on its release:

```sh
cd vendor/press
git switch -c fix/thing origin/main
# edit, commit, push, open a pull request
git checkout v0.1.0     # <- back to the release this repo is on
```

**Consumers move only to releases.** The consuming repo's pointer is always a release tag,
never a commit on `main` between releases:

```sh
git -C vendor/press fetch --tags
git -C vendor/press checkout v<version>
git add vendor/press && git commit -m "chore: bump press to v<version>"
```

---

## Traps

- **Fonts fail in three ways, and only one warns.** A missing *family* warns and still
  ships. A missing *weight or style* substitutes the nearest face silently (`weight: 400` on
  `face-display` embedded Montserrat-Bold). A missing *glyph* is drawn from Typst's embedded
  fonts silently (`→` is absent from Open Sans). Only `check` catches them.
- **`--ignore-system-fonts` does not isolate the vendored faces.** Typst's own embedded fonts
  stay reachable, so glyph fallback still happens under it.
- **The `face-*` constants are stacks, not names.** Never pass a bare font string.
- **Every document must set its body font**: `#set text(font: face-text, ...)` near the top.
  Without it the whole body renders in Libertinus Serif — no warning, exit 0. The skeleton
  has the line; hand-written documents miss it.
- **Some symbols are in no vendored face.** `✓ ✗ ▸` render from NewCMMath, `⚠ ⚡ ☐` from
  DejaVuSansMono, `ℹ` from LibertinusSerif, and **`⛔` and `📋` vanish** from the page and
  the extracted text. Before adopting a symbol, build a probe and run `check`.
- **`unit`, `band-strong` and `eyebrow` uppercase their labels.** "pH" becomes "PH", "µS"
  becomes "ΜS" (a capital Mu). Pass `caps: false` whenever case means something — `unit`
  most of all.
- **A table that crosses a page loses its header unless it uses `table.header`.** `sheet`
  does; a hand-rolled `table()` does not.
- **Markdown habits break Typst, mostly silently:**

  | You write | Typst sees | How it fails |
  |---|---|---|
  | `**bold**` | empty emphasis | **Warns, exits 0**; the emphasis vanishes. Use a single `*`. |
  | `+ thing` at line start | enumerated list item | **Silent.** Renders as a list. |
  | `/ thing` at line start | term-list item | **Compile error** — "expected colon". |

  Reword rather than escape.
- **`just all` splits its arguments on spaces.** `just build "my docs/a.typ"` works; a
  directory with a space passed to `all` does not.
- **Editing `press.just`:**
  - `just` takes the last comment line before a recipe as its description; every recipe
    carries an explicit `[doc("...")]` for that reason. Keep it, and check `just --list`.
  - `source_directory()` is press's own directory (`press_root`); `justfile_directory()` is
    the consuming repo's root (`root`). Swapping them sends output into press's tree. Under
    `--justfile`, as `all` reaches `build`, `justfile_directory()` becomes press's directory,
    which is why `all` passes `--set root`.
  - `[no-cd]` on every public recipe is required: without it a `mod` consumer resolves every
    path against press's directory.

## Do not

- **Do not add a markdown path.** Markdown-to-PDF was tried and removed. Documents are `.typ`.
- **Do not add a wrapper script.** `just` is the invocation. The files under `tools/` are
  recipes' mechanisms, kept in files so they run from PowerShell; nobody calls them instead
  of `just`.
- **Do not move whole-page composition into the library.** A helper that lays out an entire
  page belongs in the document. A styling helper a document opts into is fine to offer.
- **Do not publish to Typst Universe.** It would cost the `@vts` namespace and local
  editability.
- **Do not treat a suggestion as a decision.** A name, structure or convention you proposed
  and nobody explicitly answered is **not** approved. Ask, or leave it unbuilt.
