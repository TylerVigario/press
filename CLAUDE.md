# press — instructions for an agent

You are looking at `press`: a Typst package plus build recipes that VTS repos vendor
as a submodule. It gives a repo a **shared vocabulary and a reproducible build**, and
deliberately gives it nothing else — the page layout stays in the document.

Read this whole file before changing anything. The traps at the bottom are all real —
each one cost a debugging round the first time.

---

## The constraint everything is downstream of

**These documents are consumed as printed sheets, off-system.** Not as repo files, not
in a browser. Tyler's words: *"i consume via on-hand sheets not in frustration to
access the system that is broken: thats a wall i have to climb just to mount the
ascent."*

A document that lives only in a repo has a circular dependency — reading it requires
the system it describes to be up, reachable and logged into. Paper has no such
dependency. That is the entire reason this package exists.

What follows from it, and what you must apply to every document you write:

- **Self-contained.** No "see the other doc" carrying load, no clickable link doing
  work, no step assuming a shell or browser is available. If a fact is needed to act,
  it is on the sheet.
- **The act layer is the first section, and it runs as long as the work does.** Fitting
  one page is a goal worth aiming at — it is being held, and anything split across a page
  turn gets read half — but it is a goal, not a budget. **Content prevails.** This is
  convention 6 below, applied to the act layer, and the two used to contradict each other:
  one said no length cap, the other read as a hard page limit. When they conflict, content
  wins. A step compressed to save a line is a step that gets typed wrong at 2am, which
  costs more than a page turn ever did.
- **Commands are typed by hand off paper.** Short, unwrapped, no fragile quoting. A
  plainer command carrying the same information beats a precise one that wraps
  mid-token — and say so when you make that trade.
- **Whitespace on the act page is a feature.** It is where he writes what happened.
- **No colour-only meaning, no search, no copy-paste.** Anything that only works on a
  screen is decoration on paper.

This is a current constraint, not a permanent law. It reopens if a real audience beyond
him appears, or digital consumption genuinely displaces paper. Neither has happened.

---

## Installing press into a repo

```sh
git submodule add https://github.com/TylerVigario/press vendor/press
```

Then one line in the consuming repo's `justfile`. **Which line depends on whether that
repo already has recipes:**

| Situation | Line | Invocation |
|---|---|---|
| No justfile yet, or no name clashes | `import 'vendor/press/press.just'` | `just build docs/x.typ` |
| Repo already has its own recipes | `mod press 'vendor/press/press.just'` | `just press build docs/x.typ` |

`import` **hard-errors** on a duplicate recipe name, and press exports `build`, `watch`,
`check`, `all`, `new` and `clean` — names most repos already use. `mod` namespaces them and never
clashes. When unsure, use `mod`; it is strictly safer and costs one word at the prompt.

A repo that keeps its own `all` alongside press's must use `mod` — under `import` the two
collide and nothing builds.

After a plain `git clone` of a consuming repo the submodule directory is **empty** —
`git clone` does not honour `submodule.recurse`. The consumer needs:

```sh
git submodule update --init --recursive
```

Say this in the consuming repo's own docs. It is the single most likely first-contact
failure, and its symptom (`justfile does not exist`) does not point at submodules.

---

## Building

```sh
just build docs/services.typ     # -> print/docs/services.pdf
just watch docs/services.typ     # recompile on save
just all                         # every .typ under docs/ (fails if there are none)
just all recipes protocols pcp   # any directories — docs/ is a default, not a layout
just check docs/services.typ     # audit the built PDF for silent font failures
just new docs/thing.typ          # scaffold from the skeleton
just clean                       # delete print/
```

Output mirrors the source tree under `print/` by rule, so nobody has to remember a
convention. **`docs/` is `all`'s default argument, not a required layout** — a repo whose
directory taxonomy carries meaning (`recipes/`, `protocols/`, `pcp/`) passes its own and
restructures nothing. A build recipe that forced `docs/` would quietly make "additive, not
governing" false.

**Page orientation and size are the document's, not the library's.** The presets are
portrait US Letter; landscape is `#set page(..dense, flipped: true)`, which composes with
any of them. There is no `--landscape` flag to carry, because there is no wrapper to carry
it — the document declares what it is.

**Print at 100% — "Actual size", never "Fit to page".** The page is exactly US Letter, so
no scaling is needed or wanted; "fit" shrinks the sheet and undoes the type scale. The
presets keep all ink at least 0.5in from every edge so that 100% clears the unprintable
band consumer printers enforce in hardware, which usually has no dialog option at all. A
document that overrides `margin`, or places content absolutely (cetz canvases), can break
that on its own — measure before trusting it.

**Paths are relative to the repo root, from whichever directory you invoke.** That is
just's normal convention, restored deliberately: press's recipes carry `[no-cd]` so they
work under both `import` and `mod`, and without an explicit anchor that flag would make
output land wherever you happened to be standing.

**`build` stamps every document with when its content last changed.** It passes
`sys.inputs.press-updated`, and a document shows it with `updated()` --
in its footer, so every page carries it and a shelf copy can be checked against the
latest build. A rebuild that changes nothing on the page keeps the old time: the source is
first compiled at the previous stamp, read back from the PDF's own `/CreationDate`, and a
byte-identical result means nothing changed. The mechanism is `tools/stamp.sh`, shared with
`check` -- whose recompile would otherwise overwrite the stamped PDF with an unstamped one.
A different typst or new fonts can change an unchanged page's bytes, which re-stamps it:
that errs toward reprinting. `watch` and a bare `typst compile` pass no stamp, and
`updated()` says so rather than inventing a time. The stamp needs nothing beyond `sh`'s own
company — `date`, `grep`, `awk`, `cmp` — so `build` still needs no poppler.

**Run `check` before calling a document done.** It is not part of `build` — building must
not require poppler — so it is a separate step you have to take. `just all` does not run it
either. Five checks, each named for what it asks:

| check | asks |
|---|---|
| **warnings** | did typst warn — it exits 0 on warnings and has no deny-warnings flag |
| **font** | does the PDF draw from a face not vendored here (a *substitution*) |
| **glyph** | did every non-ASCII character in the source survive to the page (a *disappearance*) |
| **printable-area** | is any ink within 0.48in of a paper edge |
| **overlap** | is any line of text printed on top of another |

The last two catch *layout* faults the font checks cannot: ink that clips when printed at
actual size, and lines rendered over each other, which is valid typst that simply comes out
wrong. Neither shows up on screen in a way anyone notices.

Those two take opposite instruments deliberately. The printable-area check renders the page,
because "is there ink near the edge" needs no layering and must see panels and rules as well
as glyphs. The overlap check cannot render, because layering is the entire question — two
lines drawn on each other and one line drawn once are the same pixels. It reads
`pdftotext`'s line geometry, where that information survives, and so it sees glyphs only:
text over a panel is outside its reach.

Both need a working Python, and are skipped with a message when no interpreter is found.

**On Windows `python3` lies in both directions, and the cause is the App Execution
Alias.** With the alias on and no Store Python — the stock Windows state — a
zero-byte stub answers `command -v`, prints `Python was not found` and exits 49.
With the alias off, which uv's own setup recommends, there is a perfectly good
`python` and no `python3` at all. A name-based guard passes the first and skips the
second, and both are wrong.

The second is the dangerous one: the check is skipped — announced on stderr — and
the document is still reported clean, which is the part anyone acts on.
It hid a real 0.32in clipping fault here. The first has already misdirected a change
— `server-admin#82` recorded `Python was not found` in its verification notes,
concluded "so poppler does not resolve", and merged it as environmental. Wrong
subsystem; nothing to do with poppler.

So `check` probes by **executing** a candidate rather than resolving a name, and
accepts `python`. Both the printable-area and overlap checks depend on it.
`PRESS_PYTHON` and `PRESS_PDFTOPPM` name either directly, for the
same reason `PRESS_PDFTOTEXT` exists: on Windows `PATH` is not the contributor's to
order.

**The recipes exist because a bare `typst compile` will not** derive the output path,
**create the directory** (Typst refuses to write into a missing one and fails with a bare
`No such file or directory`), or carry `--root`, `--package-path`, `--font-path` and
`--ignore-system-fonts`.

Without `just`, the equivalent by hand — note `mkdir` is not optional, and there is no stamp
(`updated()` then says so):

```sh
mkdir -p print/docs
typst compile --root . --package-path vendor/press/packages \
  --font-path vendor/press/fonts --ignore-system-fonts \
  docs/services.typ print/docs/services.pdf
```

**Requirements on the building machine:** `typst`, `just` and `sh` on PATH. On Windows
`sh` comes from Git for Windows, already a prerequisite for cloning. Every recipe uses
`sh` with no `[windows]` attributes — that is `just`'s own default and primary path, and
the maintainer's direction is to select on shell *availability* rather than on OS
(casey/just#531), which makes OS attributes the workaround, not the destination.

---

## Writing a document

**Import the vocabulary, then compose the page yourself:**

```typ
#import "@vts/press:0.1.0": *
```

`just new` scaffolds a copyable skeleton. **Copy it, do not import it** — composition
belongs to the document. Two documents that need the same layout should look alike
because their authors made the same choices, not because a template forced it.

**Show rules are the document's to install.** press exports the treatment; nothing takes
effect until the document asks for it. A document with commands in it wants both of these:

```typ
#show raw: set text(font: face-mono, size: sz.micro)
#show raw.where(block: true): code
```

The first is the document's own choice of face and size. The second applies `code` — one
shaded, bordered block per listing, commands as plain lines. A document that wants a
different treatment writes its own show rule and is not deviating.

### The six conventions

These, not the tokens, are what make a sheet scannable.

1. **Meat first.** Whatever the reader must act on goes at the top. Attention is spent
   before it is earned back — never make them read design detail to reach a decision.
2. **One idea per unit, opened by a bold lead.** The lead is the highlight, pre-made,
   so nobody reaches for a marker.
3. **Units are self-contained.** Nothing may assume the unit above it was read.
   Sections get read out of order and returned to weeks later.
4. **Bands carry a role** — decide / design / reference. Skipping a section should be a
   deliberate choice, not a discovery made afterwards.
5. **Colour is state, never decoration, and it gets a legend.**
6. **No length cap.** If a unit needs depth, give it depth, or push the depth to a
   second layer — never delete it to fit a layout. If it does not fit, *the layout is
   what changes.* This one has been violated and corrected: a two-sentence cap was
   imposed once and rejected outright, because what made the good draft good was the
   sectioning and layout, not the absence of text.

The two-layer pattern that follows from 1 and 6: **the act layer comes first, the depth
layer after a `#pagebreak()`**, with an italic line saying nothing past it is needed to
act. Reference documents get the same treatment — during an incident an inventory is
consumed more than a runbook is.

Often that is literally page 1 and page 2, and it is worth aiming for. It is **not** a
requirement. The split is by ROLE, not by page number: a six-step procedure whose act
layer honestly needs two pages gets two, and the depth layer starts on page three. Sizing
the work to the layout is the failure convention 6 already forbids.

### When the conventions do not apply

**The six conventions are for a sheet read by a human. Some documents are read first by
a machine, and there the conventions actively cause harm.**

A résumé's first reader is an applicant-tracking parser. `pdftotext -layout` must yield
clean single-column reading order, or the parser mis-assigns fields — one has already
swallowed a section header as an employer name and dropped three work-experience
entries. `unit`, `chip` and two-column grids destroy exactly that. So an ATS résumé
takes press's **tokens and fonts** and none of its **layout conventions**, and that is
correct, not a deviation to be tidied up later.

This is legal because **press is additive, not governing** — it sets no page, installs
no show rule, and assumes no layout. A document takes what serves its reader. Before
"improving" a document into house style, establish who reads it first; if the answer is
a parser, leave it single-column and say so in a comment at the top of the file.

### Vocabulary

Tone is a string: `"note"` (slate) · `"ok"` (green) · `"warn"` (amber) · `"bad"` (red).

| Call | For |
|---|---|
| `unit(label, tone, lead, body, caps:)` | The workhorse. One idea: label, bold lead, body. |
| `band-strong(title, role, color:, caps:)` | Section header carrying its role. |
| `band(label, color: slate)` | Lighter section header. |
| `titlebar(title, meta, color:, face:, size:)` | Document head with right-aligned meta. |
| `eyebrow(body, color:, caps:)` | Small tracked-out uppercase label. |
| `chip(label, tone)` | Inline state pill — build legends from these. |
| `callout(body, tone: "note", label: none)` | Aside that must not be missed. |
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
`body` 11 · `lead` 12.5 · `head` 14.5 · `title` 21 · `hero` 28 — sized for paper, not a
screen you can zoom. Page presets `dense`,
`reading`, `card` — spread with `#set page(..card)`.

**When the vocabulary does not fit, build it in the document.** That is correct and
expected — a document may always write what it needs inline, and nothing has to be
promoted here to be legitimate.

**There is no threshold something must clear before it may be offered here.** Propose it.
`press` does not gate its own contents: a gate is enforcement, and **documents vary
enormously** — a printed runbook, a service inventory and an ATS résumé share fonts and
almost nothing else — so nothing can decide in advance what will prove useful to them. A
helper nobody calls costs a document nothing.

`sheet` shows what a well-founded promotion looks like: the same wide-table helper had
gone byte-identical across documents in two repositories. That is evidence noticed
afterwards, not a bar cleared beforehand.

---

## Changing press itself

**Do not edit a released version directory in place.** Consumers pin `@vts/press:0.1.0`
and a silent change under them is the whole failure mode packages exist to prevent.
Copy `packages/vts/press/0.1.0/` to the new version, edit there, bump `version` in its
`typst.toml`, and let consumers move when they choose. The rule starts at a version's first
release: until then its directory takes additions, which is how `updated()` came into
0.1.0. From the release on it holds without exception.

**The release is the tag, and CI holds it.** `v<version>` names one directory, and the
*Released versions are unchanged* job compares every such directory with its tag on each
pull request. An edit fails the check, and so does a removal or a tag whose directory
does not exist, so the rule above is refused at merge rather than trusted.

**Committing back from a submodule.** A submodule checks out a **detached HEAD**, so
committing there and pushing appears to work and then loses the commit. Always:

```sh
cd vendor/press
git checkout main       # <- the step that is forgotten
# edit, commit, push
cd ../..
git add vendor/press && git commit -m "chore: bump press"
```

The consuming repo stores a **commit pointer**, not the files. Both commits are needed:
one in press, one recording the new pointer.

---

## Traps

- **Fonts fail in three ways, and only the loudest one warns.** A missing *family* emits
  `warning: unknown font family` — and Typst 0.15 has no deny-warnings flag, so it still
  ships. A missing *weight or style* says nothing at all: the family is present, so the
  nearest face is substituted and the build exits 0 (verified — `weight: 400` on
  `face-display` embedded Montserrat-Bold when Regular was not vendored). A missing
  *glyph* also says nothing: that one codepoint is drawn from Typst's embedded
  Libertinus Serif (verified — `→` is absent from Open Sans; press's own `flow()` shipped
  stray serif arrows because of it).
- **`--ignore-system-fonts` does not isolate the vendored faces.** It removes the
  *machine's* fonts, which is what makes output machine-independent — but Typst's own
  embedded fonts stay reachable, which is why the glyph-level fallback still happens
  under it. Do not cite it as protection against a wrong PDF.
- **The `face-*` constants are stacks, not names.** Head is intended, tail is a vendored
  fallback for absent glyphs. Keep them that way; passing a bare string re-opens the
  glyph hole.
- **Every document must set its body font.** `#set text(font: face-text, ...)` near the
  top. Omit it and the *entire body* renders in Typst's default Libertinus Serif — no
  warning, exit 0, and it does not look obviously broken at a glance. The skeleton
  includes the line; a hand-written document is where this bites.
- **The stacks narrow the glyph hole, they do not seal it.** A codepoint absent from
  every vendored face still comes from Typst's own bundled fonts, and some are dropped
  entirely. Measured on this package: `✓ ✗ ▸` render from NewCMMath, `⚠ ⚡ ☐` from
  DejaVuSansMono, `ℹ` from LibertinusSerif, and **`⛔` and `📋` vanish from the page and
  from the extracted text.** A substitution ships the wrong glyph; a disappearance ships
  missing content. Before adopting a symbol vocabulary, build a probe and run `check`.
- **`just check` is the only thing that catches any of this.** Run it before calling a
  document done; read its LIMITS comment in `press.just` before trusting it past its
  reach.
- **`just all` splits its arguments on spaces.** A directory whose name contains one
  fails with a confusing message rather than working. `just build "my docs/a.typ"`
  handles the same path correctly — it is only the variadic that splits.
- **`just` takes the LAST contiguous comment line before a recipe as its doc string.**
  A multi-paragraph rationale block therefore puts its closing fragment into
  `just --list` — five of six recipes here once listed as things like
  "# the anchor correct through the recursion." Every recipe now carries an explicit
  `[doc("...")]` attribute, which is immune to comment layout. Keep it that way when
  adding a recipe, and check `just --list` after editing comments.
- **`unit`, `band-strong` and `eyebrow` uppercase their labels, which silently corrupts
  case-carrying strings.** "pH" becomes "PH", "iOS" becomes "IOS", and "µS" becomes "ΜS" —
  the micro-sign replaced by capital Mu, a different character. Pass `caps: false` whenever
  the case of a label means something. **`unit` matters most**: it is the most-used call in
  the vocabulary, and its label goes through `eyebrow`. The default is `true` so existing
  documents are unchanged, which also means this stays easy to hit.
- **A table that crosses a page loses its header unless it goes through
  `table.header`.** `sheet` does this; a hand-rolled `table()` in a document will not.
  Measured: a 140-row table showed its column labels on page 1 and bare rows on pages 2
  and 3. On paper there is no scrolling back, so the reader gets numbers with no idea
  what column they are in.
- **`typst` will not create the output directory.** Hence `mkdir -p` in `watch` and in
  `tools/stamp.sh`, which `build` and `check` run — everything that writes a PDF.
- **The two directory functions mean opposite things here, and both are used.**
  `source_directory()` resolves relative to `press.just` itself — that is `press_root`,
  how the package and fonts are found wherever press is vendored. `justfile_directory()`
  resolves to the *consuming* repo's root — that is `root`, where `print/` belongs and
  what every recipe cds to. Swapping them silently sends output into press's own tree.
  One exception: under `--justfile` (how `all` reaches `build`) `justfile_directory()`
  becomes press's directory, which is why `all` passes `--set root` explicitly.
- **`[no-cd]` on every public recipe is load-bearing.** Without it a `mod` consumer runs
  with press's own directory as the working directory and every document path resolves
  against the wrong tree — `error: input file not found`.
- **Typst has no deny-warnings flag, so `build` exits 0 on warnings.** `just check` now
  recompiles and fails on any, because "warnings must be read" is not a mechanism.
- **Markdown habits produce three distinct Typst failures, and only one of them is loud.**
  All three were hit while converting real documents:

  | You write | Typst sees | How it fails |
  |---|---|---|
  | `**bold**` | empty emphasis | **Warns, exits 0.** The emphasis silently vanishes — caught only by `check`. Use a single `*`. |
  | `+ thing` at line start | enumerated list item | **Silent.** Renders as a list rather than text. |
  | `/ thing` at line start | term-list item | **Compile error** — "expected colon". The only one that stops you. |

  The first two reach paper looking almost right, which is the worst outcome. Reword rather
  than escape: a leading operator is rarely load-bearing, and escaping it leaves the next
  editor the same trap.
- **Typst has no output-path config.** Paths come from the recipes.
- **`git clone` ignores `submodule.recurse`.** Only `--recursive`, or a follow-up
  `git submodule update --init --recursive`, populates `vendor/press`.

## Do not

- **Do not add a markdown path.** Markdown-to-PDF was tried here and removed. It is
  less configurable and fiddlier at exactly the moments that matter. Documents are
  `.typ`. The only markdown that stays is the git conventions — `README`, `LICENSE`,
  `CLAUDE.md`, and this file.
- **Do not add a wrapper script.** A `build.sh` and a `print-doc` were both written and
  both deleted. (`tools/check.sh` and `tools/stamp.sh` are not wrappers: each is a recipe's
  mechanism, in a file only so it runs from PowerShell. Nobody invokes them instead of
  `just`.) `just` is the invocation: one file instead of a POSIX and a PowerShell
  twin that would inevitably drift, identical arguments on every platform, with recipe
  listing and dependencies for free.
- **Do not move whole-page composition into the library.** A helper that lays out an
  entire page belongs in the document that needs it — that is what "not governing" is
  protecting, because documents vary too much to share a page. It is **not** a bar on
  styling: a helper a document opts into, including a show rule the document installs
  itself, enforces nothing and is fair to offer. Do not rule styling out of scope on the
  package's behalf.
- **Do not publish to Typst Universe.** Deliberate — see the README.
- **Do not treat a suggestion as a decision.** If you propose a name, a structure or a
  convention and it is not explicitly answered, it is **not** approved. Ask, or leave it
  unbuilt. This repo was briefly built under the wrong name that way.
