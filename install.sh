#!/bin/sh
# install.sh — install press as ./press, or update the copy there, from the release this
# installer is attached to.
#
#   curl -fsSL https://github.com/TylerVigario/press/releases/latest/download/install.sh | sh
#   wget -qO- https://github.com/TylerVigario/press/releases/latest/download/install.sh | sh
#
# Run it in the directory press lives in (vendor/, say). It downloads its release's
# press.tar.gz, refuses the archive unless its SHA-256 is the one written below, unpacks it
# beside press/ and swaps it in whole, so a file a release removed does not linger. A press/
# that is not a press kit, or is a git checkout, is left alone, and nothing is left behind but
# press/.
#
# Each release attaches its own installer, its version and its archive's sum written in by
# .github/bundle.sh: latest/download/install.sh installs the latest release, and
# download/v<version>/install.sh installs that one. PRESS_BASE_URL fetches the archive from
# another address: a mirror, or CI's local copy.
#
# It needs sh, curl or wget, sha256sum or shasum or openssl, mktemp, tar with gzip, sed, mv
# and rm. Everything is in main, called on the last line, so a download cut short runs nothing.
set -eu

die() { echo "press: $*" >&2; exit 1; }

fetch() {
    if command -v curl >/dev/null 2>&1; then curl -fsSL -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then wget -q -O "$2" "$1"
    else die "needs curl or wget to download $1"; fi
}

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"
    elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1"
    elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 -r "$1"
    else die "needs sha256sum, shasum or openssl to check the download"; fi
}

# Puts the old copy back if it was moved aside and the new one is not in its place, then
# removes the temporary directory: on success, on failure and on interrupt alike.
cleanup() {
    if [ -e "$tmp/old" ] && [ ! -e press ]; then mv "$tmp/old" press; fi
    rm -rf "$tmp"
}

main() {
    version='@VERSION@'
    sum='@SHA256@'
    case $version$sum in
        *@*) die "this is the installer's source, with no release written in; run a release's:
       curl -fsSL https://github.com/TylerVigario/press/releases/latest/download/install.sh | sh" ;;
    esac
    base=${PRESS_BASE_URL:-https://github.com/TylerVigario/press/releases/download/v$version}

    if [ -f press.toml ] && [ -f lib.typ ]; then
        die "this is press's own directory; run the installer in the directory that holds press/"
    fi
    if [ -e press/.git ]; then
        die "./press is a git checkout, such as the 0.1.0 submodule; remove it (git rm press) and run this again"
    fi
    if [ -e press ] && [ ! -f press/press.toml ]; then
        die "./press is not a press kit; move it aside and run this again"
    fi

    # Beside press/, so both moves below are renames on one filesystem.
    tmp=$(mktemp -d .press-install.XXXXXX)
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    fetch "$base/press.tar.gz" "$tmp/press.tar.gz" || die "could not download $base/press.tar.gz"
    got=$(sha256 "$tmp/press.tar.gz")
    got=${got%% *}
    if [ "$got" != "$sum" ]; then
        die "press.tar.gz is not the archive press $version was released with; nothing changed
       expected $sum
       got      $got"
    fi
    (cd "$tmp" && tar -xzf press.tar.gz)

    was=
    if [ -e press ]; then
        was=$(sed -n 's/^version *= *"\(.*\)"$/\1/p' press/press.toml)
        mv press "$tmp/old" || die "could not move the old press/ aside; nothing changed"
    fi
    mv "$tmp/press" press || die "could not put the new press/ in place; nothing changed"

    where="$(pwd)/press"
    if [ -z "$was" ]; then echo "press: installed $version in $where"
    elif [ "$was" = "$version" ]; then echo "press: reinstalled $version in $where"
    else echo "press: installed $version in $where, replacing $was"; fi
}

main "$@"
