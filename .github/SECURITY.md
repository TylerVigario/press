# Security

press is files a repository holds and the tools it runs with them: `tools/`, which builds,
stamps and audits every document, `press.just`, and the installers each release attaches. A
flaw in any of them runs on the machine of everyone who builds with press, so report it
privately.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: [report a
vulnerability](https://github.com/TylerVigario/press/security/advisories/new), under this
repository's Security tab. The report reaches the repository's maintainers and no one else, and
it and its fix are worked out there until a release carries the fix.

Say which press it is, the `version` in your copy's `press.toml`, which typst
(`typst --version`), and on what system, and give the steps or the document that show it.

Do not open a public issue or pull request for a vulnerability.

## Which versions are fixed

A fix goes into the next release. A repository holds its own copy of press, so it takes the
fix by running the installer again, which moves its copy to the newest release.
