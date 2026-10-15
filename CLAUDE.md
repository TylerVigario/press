# press — instructions for an agent working on press

press is a scaffolding kit for Typst documents: a folder of files a repository holds and
imports by path. This file is for changing press itself. **Using press in a repository is
README.md's** — it ships in every release, and an agent in a consuming repository reads that.

Read this whole file before changing anything. Every trap listed has already happened.

---

## What press is, and what it is not

**A kit of files, imported by path.** A document writes `#import "/vendor/press/lib.typ": *`
and builds with plain typst and press's fonts. There is no namespace and no version in any
import; the copy a repository holds is the version it builds with.

**Universal.** A repository takes press with the tools its system already has — the
installers README.md gives one line each — and builds from whatever runner it already uses. It
never adopts just, or anything else, for press. `press.just` is one adapter, for repositories
that use just already; underneath it are plain typst and the `sh` scripts in `tools/`, which
any runner calls.

**One output for screen and print.** Every part must work in both media: a part that works in
only one is not finished.

**Additive.** press sets no page and installs no show rule of its own accord. A document takes
the parts it wants and composes its own page.

press grows from the documents that use it: a template or part is added when a real document
needs it, built for both media, and offered to every document from the next release.

---

## The tree

| | what |
|---|---|
| `lib.typ` | the parts, tokens and presets a document imports |
| `press.toml` | `version`, the version last released, and `typst`, the oldest typst press works with |
| `template/main.typ` | the skeleton `tools/new.sh` copies; imports `../lib.typ` so it compiles in place |
| `calibration.typ` | the print calibration sheet; imports `lib.typ` |
| `fonts/` | the vendored faces, and `fonts/licenses/` with each one's licence text |
| `tools/` | `new.sh`, `stamp.sh`, `check.sh`, `report.sh`, and the audit's two Python passes |
| `press.just` | recipes for repositories that use just |
| `README.md`, `FONTS.md`, `LICENSE` | the consumer guide, the font account, the AGPL |
| `install.sh`, `install.ps1` | the installers each release attaches beside the kit, not inside it |
| `.github/`, `CLAUDE.md`, `CHANGELOG.md`, `cog.toml`, `justfile` | press's own machinery |

**The release bundle is an allowlist** in `.github/bundle.sh`: the kit rows above, nothing of
the machinery. A file the kit needs is added there on purpose; anything else stays out.

**The installers in the tree are templates.** `bundle.sh` writes `press.toml`'s
version and the SHA-256 of the archive each one fetches over their `@VERSION@` and `@SHA256@`,
so a release's installer installs that release and refuses any other bytes. Unstamped, they
refuse to run.

**`press.toml` is the one place each version is written.** `lib.typ` reads it — `press-version`
prints `version`, and an assert refuses a typst older than `typst` — and `tools/stamp.sh` reads
`typst` before the flags an older typst would stop on. It is not a `typst.toml`: press is not
a Typst package, and the audit treats a directory holding a `typst.toml` as a package's.

---

## Changing press

**Every change is a pull request.** `main` takes no direct pushes, and a pull request merges
only once its checks ran against the current main. Pull requests squash-merge with the title
as the commit, so the title must be a conventional commit; the type decides the next version.

**CI** builds and audits the calibration sheet, compiles the template in place and as
`new.sh` scaffolds it, rebuilds to prove an unchanged page keeps its stamp, does all of that
again at the oldest typst and just press accepts, builds the release bundle and installs it in
a scratch repository to scaffold, build and audit there with no just, runs both installers
against the bundle served locally (install, update, refusals), and runs shellcheck,
markdownlint (lines ≤ 100), actionlint, a JSON parse, an invisible-character scan and CodeQL.
The tools CI installs are pinned by hand, with digests; the weekly Pins workflow opens an issue
for each release a pin is behind (`sh .github/pins.sh` shows the same comparison).

**The floors** are `press.toml`'s `typst` and `press.just`'s `set minimum-version`. CI's
oldest-toolchain job installs exactly those, from the toolchain action's `OLDEST_` pins, and
refuses to run if they disagree. Raising a floor is a deliberate edit in both places.

**Versions are tags.** Nothing in the tree is named for a version, so a change is made where
the file is, with nothing to copy or rename.

**Releasing is one run of the Release workflow, dry run first.** It derives the version from
the commits, gates on CI, writes the version into `press.toml` and `CHANGELOG.md` into a
`release:` commit by the `vigario-press-release` App, builds the bundle, and publishes the
GitHub release with `press.tar.gz`, `press.zip`, `install.sh`, `install.ps1` and `SHA256SUMS`
attached; publishing creates the tag. Never tag by hand. If it fails after the `release:`
commit has landed, start a new run rather than re-running the failed one: a re-run checks out
the old commit and the forge refuses its commit. `CHANGELOG.md` is generated except for its
hand-written first release, "Initial release.", which `.github/write-changelog.sh` keeps (until
cocogitto/cocogitto#580 is fixed).

**When behaviour changes, change README.md with it.** It is the only guide a consuming
repository has.

---

## Traps

- **The template's import line is an interface.** `new.sh` rewrites exactly
  `#import "../lib.typ": *` into the copy's root-relative path, and refuses if the line is not
  there. Keep the line as it is, or change both.
- **The audit's glyph scan leaves out exactly press's `lib.typ`**, found beside `press.toml`,
  and the files of any Typst package, found beside a `typst.toml`. A document kept in press's
  directory, such as the calibration sheet, is still scanned.
- **Editing `press.just`:**
  - `just` takes the last comment line before a recipe as its description; every recipe
    carries an explicit `[doc("...")]` for that reason. Keep it, and check `just --list`.
  - `source_directory()` is press's own directory (`press_root`); `justfile_directory()` is
    the consuming repository's root (`root`). Swapping them sends output into press's tree.
    Under `--justfile`, as `all` reaches `build`, `justfile_directory()` becomes press's
    directory, which is why `all` passes `--set root`.
  - `[working-directory(root)]` on every recipe is required: without it a `mod` consumer
    resolves every path against press's directory.
  - `all` takes its directories as the shell's own arguments: it is `[positional-arguments]`
    and reads `"$@"`. Interpolating `{{ dirs }}` joins every name into one string and splits a
    name with a space in it.
- **The installers' stamp lines are an interface.** `bundle.sh` substitutes them and
  `bundle-check.sh` finds them by their exact text, indentation included (`version='…'` in
  `install.sh`, `$sum = '…'` in `install.ps1`). Change all three together.
- **`install.ps1` is ASCII only.** Windows PowerShell reads a script with no byte order mark in
  the system's code page. It throws instead of exiting: run through `irm | iex` in someone's
  session, `exit` would close it.
- **The tools run in Git's `sh` on Windows**, from `cmd.exe`, PowerShell and npm alike. Keep
  them POSIX `sh`, and test Windows through the laptop before claiming it works.

## Do not

- **Do not make press a Typst package again.** A package cannot hand fonts to the compiler or
  carry the tools beside it, and a version in every import only restates what the copy a
  repository holds already says.
- **Do not make a repository need just,** or any one runner. Whatever press does must be
  reachable with plain typst and `sh`.
- **Do not add a markdown path.** Markdown-to-PDF was tried and removed. Documents are `.typ`.
- **Do not move whole-page composition into the library.** A helper that lays out an entire
  page belongs in the document. A styling helper a document opts into is fine to offer.
- **Do not treat a suggestion as a decision.** A name, structure or convention you proposed
  and nobody explicitly answered is **not** approved. Ask, or leave it unbuilt.
