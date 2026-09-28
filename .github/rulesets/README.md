# Rulesets

`main.json` is the branch protection payload for this repository. It is committed
because a ruleset is applied state that lives only on GitHub: it vanishes silently on
repository recreate, rename or fork, and nothing in a clone reveals it is gone.

The file is the source of truth. Apply it, do not hand-configure:

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

`Lint main` is deliberately **not** required. It runs on `push` and cannot report on a
`pull_request` event, so requiring it would leave every pull request waiting on a
context that never arrives.

**`bypass_actors: []`** — an actor-based exemption is inherited by anything
authenticating as that actor. On a single-owner repository "repository admin" exempts
the owner *and* every automation acting on the owner's behalf, which is the entire
population the rule exists to constrain. To push directly, set `enforcement` to
`disabled` first — a deliberate, visible act with a record.

## Not included

No tag ruleset. This repository publishes no releases and carries no version tags, so
there is no `refs/tags/v*` namespace to make immutable. Add `tag-protection` alongside
the first tag, not before it — a rule guarding a namespace nothing writes to is a claim
without a subject.

## Why this repository is worth protecting more than most

Every repository that builds a document vendors `press` as a submodule. A bad commit on
`main` here reaches all of them, and their own pointer checks only assert that the pin is
*reachable* on this branch — not that this branch is any good.
