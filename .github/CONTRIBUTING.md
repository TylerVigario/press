# Contributing to press

press is a folder of files a repository holds and imports by path. This guide is for changing
press itself; using it is the README's. [CLAUDE.md](../CLAUDE.md) holds the traps a change has
already fallen into, and is worth reading before a change of any size.

## Set up

- **typst** 0.14.0 or newer. CI builds with the version `tools/install-typst.sh` pins, and
  `sh tools/install-typst.sh <dir>` installs it on Linux.
- **The audit's tools**: poppler (`pdffonts`, `pdftotext`, `pdftoppm`), Python 3, and a grep
  with PCRE, GNU grep. The README's *Requirements* and *On Windows* say where each comes from.
- **just** 1.55 or newer, if you want the recipes. press's own `justfile` imports `press.just`.

## Build and audit

```sh
just build calibration.typ     # or: sh tools/build.sh calibration.typ
just check calibration.typ     # the audit alone, which refuses without its tools
```

Every build is audited where the tools are installed, and says in one line what it made.

## Test a change

Most checks CI runs are a script you can run, `sh .github/<name>.sh`. The documents' build and
audit are `just build calibration.typ` and `just check calibration.typ`, as above, and the lints
below run their own tools. Those that touch what you changed are the ones to run first:

- `audit-cases.sh`: the audit's known cases, `.github/audit-cases/`
- `templates.sh`: each starter compiles in place and as `new.sh` scaffolds it
- a layout check, such as `list-spacing.sh`, each with the `.typ` it measures

CI runs each check that compiles with typst at the typst `tools/install-typst.sh` pins and again
at the oldest press accepts, `press.toml`'s `typst`, so a change that needs a newer typst fails
there; the release bundle's check alone runs at press's typst only. `tools/install-typst.sh`
installs the newer. The oldest is typst's own release of that version, whose address and digest
the toolchain action's `OLDEST_` pins give, in `.github/actions/typst-toolchain/action.yml`.
Run the checks you touched at both.

## Shape a pull request

- **One concern a pull request.** A fix and the check that proves it go together, and an
  unrelated tidy goes in its own.
- **The title is a Conventional Commit**, and the pull request squash-merges with it as the
  commit. Its type sets the next version: `feat` moves the minor version, `fix` the patch, and
  `docs`, `ci`, `refactor` and the rest none. A breaking change moves the major from 1.0.0 on;
  below it, cocogitto moves the minor, as for a `feat`, so a 0.x release may break.
- **The description says what changed and what was measured**, and closes the issue it
  fixes: `Closes #123`.
- **When behaviour changes, change the README with it.** It is the only guide a repository
  using press has.

`CHANGELOG.md` and `press.toml`'s `version` are written by the release; a pull request does not
edit them.

## Add a check

A fix to how a page is laid out comes with a check that fails without the fix:

- **A layout check** is a `.github/<name>.sh` and the `.typ` it measures. Each is a job of its
  own in `.github/workflows/ci.yml`, once on press's typst and once on the oldest toolchain,
  named for what it asserts and then `, on the oldest toolchain`. Both names go in
  `.github/rulesets/main.json`, and `sh .github/contexts.sh` checks the jobs and the ruleset
  agree. GitHub cuts a check's name past 100 characters, so a name keeps to 75 before that
  suffix.
- **A false finding the audit made, once fixed,** gets a `.github/audit-cases/pass-*.typ`, and
  a fault a pass must catch a `fail-*.typ` with its `// expect:` line.

## Lints

CI also runs shellcheck at `--severity=warning`, over press.just's recipes and every composite
action's `run:` steps too; markdownlint, lines at most 100; actionlint; a JSON parse; and a scan
for soft hyphens, zero-width characters and direction controls in any tracked file.

## Releases

A maintainer cuts each release with the Release workflow, which takes the version from the
commits since the last one.
