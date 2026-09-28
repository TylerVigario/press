#!/bin/sh
# setup-cog.sh — make a pinned cocogitto usable in any job that runs it.
#
# Setup rather than install, because installing the binary is not sufficient to run
# it: see the git identity below.
#
# A file rather than a copy of the same block in every job that needs it. A
# duplicated install is a duplicated pin: the version and digest would sit in two
# places and drift apart at the first bump, which is the failure the digest exists to
# prevent.
#
# A plain script rather than a composite action, even though rule 5 asks for a
# composite for anything used twice. A composite is right for the typst toolchain
# beside it, which has inputs and conditional steps. This has neither, and a
# directory plus an action.yml to wrap five lines of curl costs a reader one more
# file before they learn what runs.
#
# Invoked as `sh .github/setup-cog.sh`, the same way press.just runs tools/check.sh
# and for the same reason: handing the file to an interpreter depends on nothing
# about the file itself. The mode bit is set and the shebang is here so it can also
# be run directly, but neither is load-bearing — a mode lost through an archive, an
# export or a filesystem that does not carry one leaves the workflow working.
#
# The pin lives HERE, not in a workflow's env. It was once set at the workflow level,
# which kept it single while one workflow ran cog; the moment a second one does, a
# workflow-level pin becomes two pins. This file is the one place to edit on a bump.
set -eu

# Pinned by version AND by digest. The binary comes from a third-party release page,
# a tag can be moved, and this runs on every pull request — a version alone is a pin
# against accident, not against substitution. Dependabot does not see it; a bump is
# a deliberate edit of both lines, and CI proves the digest before it can merge.
COG_VERSION=7.0.0
COG_SHA256=e03938ff2c4c86d71c00c0f3284dbbe95c5ca76fe34a51f33e945c23010d59bb

target=x86_64-unknown-linux-musl
url="https://github.com/cocogitto/cocogitto/releases/download/${COG_VERSION}/cocogitto-${COG_VERSION}-${target}.tar.gz"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

# --fail so an HTML error page is an error rather than a tarball that fails to
# extract three lines later with a message about gzip.
curl --fail --silent --show-error --location "$url" --output "$tmp/cog.tar.gz"

# Verified BEFORE extraction. A digest checked after unpacking has already let the
# archive choose its own paths.
echo "${COG_SHA256}  ${tmp}/cog.tar.gz" | sha256sum -c -

tar -xzf "$tmp/cog.tar.gz" -C "$tmp"
sudo install -m 0755 "$tmp/${target}/cog" /usr/local/bin/cog

cog --version

# A git identity, because `cog verify` ABORTS without one.
#
# Not findable on a workstation: any machine that has ever committed has a
# user.name, so verify works everywhere except a fresh runner, which has no
# ~/.gitconfig. cog unwraps the lookup:
#
#   thread 'main' panicked at crates/cocogitto/src/bin/cog/main.rs:584
#   called `Result::unwrap()` on an `Err` value:
#     Other(Error { code: -3, klass: 7, message: "config value 'user.name' was not found" })
#
# Exit 134, a core dump, and a failed check whose message says nothing about commit
# conventions. Reproduced with an empty HOME, and fixed by exactly this.
#
# It must be a real config entry. GIT_CONFIG_COUNT / GIT_CONFIG_KEY_n was the tidier
# candidate and it does NOT work — libgit2 does not read those, and the panic is
# unchanged. Measured, not assumed.
#
# `cog check` does not need an identity; only `verify` does. Both jobs get it anyway,
# because Lint main falls back to `verify` when its range is unanswerable, and that
# fallback exists precisely for the disordered cases nobody rehearses.
#
# Nothing here ever commits. cog reads the identity only to print an author beside
# the message it is checking.
git config --local user.name github-actions
git config --local user.email 'github-actions[bot]@users.noreply.github.com'
