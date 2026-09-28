# Rulesets

`main.json` is the branch protection payload for this repository, and `tag.json` the tag
protection payload. They are committed because a ruleset is applied state that lives only
on GitHub: it vanishes silently on
repository recreate, rename or fork, and nothing in a clone reveals it is gone.

Each file is the source of truth. Apply it, do not hand-configure:

```bash
# create
gh api repos/<org>/<repo>/rulesets --method POST --input .github/rulesets/main.json

# update an existing one
gh api repos/<org>/<repo>/rulesets/<id> --method PUT --input .github/rulesets/main.json
```

Read back what is actually enforced — from the **rules** endpoint, not the legacy
branch-protection API, which reports `enforcement_level: off` even where a ruleset is
demonstrably active:

```bash
gh api repos/<org>/<repo>/rules/branches/main
```

The file carries only the fields the create and update endpoints accept. `id`,
`node_id`, `source` and `created_at` are server-assigned; committing them would invite
someone to edit a value the API ignores.

## Why each rule

**`pull_request`, 0 approvals** — a single owner cannot approve their own pull request,
so requiring one deadlocks the repository outright. The pull request is the record; the
approval count adds nothing where there is one reviewer.

**`allowed_merge_methods: squash`** — no merge commits, and no rebase either. A second
parent buys nothing merging into linear history; rebase is excluded because it replays
branch commits onto main verbatim, so a check validating the pull request title never
sees them.

**`deletion`, `non_fast_forward`** — the branch cannot be removed or rewritten.

**`required_linear_history`** — not the same lever as disabling merge commits in the
repository settings. Merge methods are settings: one API call re-enables them, touching
no ruleset and leaving nothing in the ruleset history. The rule holds the shape against
a setting drifting back.

**`required_status_checks`** — one context per assertion, no aggregate:

| context | asserts |
| --- | --- |
| `Documents build` | typst compiles every document |
| `Documents pass the audit` | the warning, font and printable-area passes |
| `No invisible characters` | no soft hyphens or zero-width characters in any tracked file |
| `Released versions are unchanged` | every tagged package version directory still matches its tag |
| `JSON parses` | every tracked `*.json`, including these payloads, parses |
| `Markdown lint` | every tracked `*.md` passes markdownlint |
| `Workflows lint` | every workflow passes actionlint, with shellcheck on each `run:` block |
| `Shell scripts lint` | every `*.sh` in the tree passes shellcheck |
| `Validate PR title` | the pull request title parses as a Conventional Commit |

These are **job names**, taken from each job's `name:` field. Renaming a job disables
that gate without a word of warning, and adding a job without adding its context here
leaves protection reading as complete while covering less. To change one: relax the
rule, merge the change, tighten it again, then verify against the rules endpoint.

The title, not a part of it. "Subject" is avoided above because it means two different
things in a repository that lints commits: git's subject is the whole first line, while
Conventional Commits calls the text after the colon the description and commitlint calls
that the subject. What the gate reads is the entire title string. Under squash that title
becomes the commit subject in git's sense, which is rule 9.

**`code_scanning`, CodeQL** — findings, not jobs, are what gate here. *Analyze actions* and
*Analyze python* pass whenever the analysis ran, whatever it found, so requiring them as
contexts would assert only that CodeQL executed. This rule refuses the merge when the pull
request introduces a security alert of medium severity or higher, or any alert at error level,
and waits for CodeQL's result, which is why CodeQL runs on every pull request with no paths
filter. A false positive is dismissed in the Security tab, with a reason, rather than by
loosening the threshold.

`Lint main` is deliberately **not** required. It runs on `push` and cannot report on a
`pull_request` event, so requiring it would leave every pull request waiting on a
context that never arrives.

**`bypass_actors: []`** — an actor-based exemption is inherited by anything
authenticating as that actor. On a single-owner repository "repository admin" exempts
the owner *and* every automation acting on the owner's behalf, which is the entire
population the rule exists to constrain. To push directly, set `enforcement` to
`disabled` first — a deliberate, visible act with a record.

## tag.json

A tag here names a released package version, and consumers pin that version in their
imports. One version must never name two sets of bits, so a tag is create-once. It was
applied before the first tag, `v0.1.0`, because a rule guarding a namespace that is
already written to has arrived late.

**`deletion`, `non_fast_forward`, `update`** — all three, because the first two read as
complete tag protection and are not. They stop a tag being removed or pointed backward,
but advancing a tag to a descendant is a fast-forward, so the rule written to catch a
rewrite stays silent while the name comes to cover different bits. `update` refuses any
move of a tag that already exists and still admits one that does not.

**`~ALL`**, not `refs/tags/v*` — no tag in this repository should move, whatever its name.

**No `creation` rule and `bypass_actors: []`** — anyone with write access may name a
version, and nobody may change one. A bypass reaches a whole ruleset, so an actor allowed
past `creation` would be past `update` and `deletion` too, which would cost the only
property this ruleset exists to provide. Creating a tag is open, so the release workflow,
whose App creates the tag when it publishes, needs no exemption here.

Read it back by id, since the rules endpoint answers for branches only:

```bash
gh api repos/<org>/<repo>/rulesets --jq '.[] | select(.target == "tag") | .id'
gh api repos/<org>/<repo>/rulesets/<id>
```

And prove it rather than read it, on a scratch tag rather than a release. The release
workflow creates its tag at the moment it publishes, and an immutable release locks the tag
as well, so a refusal on a released tag no longer says which of the two refused it. Push
`probe/tag-ruleset` at one commit, then try to move it with
`git push --force origin <other-commit>:refs/tags/probe/tag-ruleset`: the push must be
refused, and so must deleting it. Removing the probe then takes `enforcement: disabled`,
which is a visible act with a record, and re-enabling it at once.

## Why this repository is worth protecting more than most

Every repository that builds a document vendors `press` as a submodule. A bad commit on
`main` here reaches all of them, and their own pointer checks only assert that the pin is
*reachable* on this branch — not that this branch is any good.
