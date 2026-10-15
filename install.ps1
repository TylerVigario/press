# install.ps1 - install press as .\press, or update the copy there, from the release this
# installer is attached to.
#
#   powershell -NoProfile -c "irm https://github.com/TylerVigario/press/releases/latest/download/install.ps1 | iex"
#
# Run it in the directory press lives in (vendor\, say), from PowerShell or cmd.exe. It
# downloads its release's press.zip, refuses the archive unless its SHA-256 is the one written
# below, unpacks it beside press\ and swaps it in whole, so a file a release removed does not
# linger. A press\ that is not a press kit, or is a git checkout, is left alone, and nothing is
# left behind but press\. Windows PowerShell 5.1 and PowerShell 7 alike, the Restricted
# execution policy included: it loads no script module. -NoProfile keeps the user's profile, and
# whatever it loads, out of the run.
#
# Each release attaches its own installer, its version and its archive's sum written in by
# .github/bundle.sh: latest/download/install.ps1 installs the latest release, and
# download/v<version>/install.ps1 installs that one. PRESS_BASE_URL fetches the archive from
# another address: a mirror, or CI's local copy.
#
# Everything is in one script block, run as a whole: a download cut short does not parse, so
# nothing runs, and nothing it sets stays in the session that ran it. A failure throws rather
# than exits, which would close that session. ASCII only: Windows PowerShell reads a script
# with no byte order mark in the system's code page.

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    $version = '@VERSION@'
    $sum = '@SHA256@'
    if (($version + $sum).Contains('@')) {
        throw ("press: this is the installer's source, with no release written in; run a release's:`n" +
            '  powershell -NoProfile -c "irm https://github.com/TylerVigario/press/releases/latest/download/install.ps1 | iex"')
    }
    $base = $env:PRESS_BASE_URL
    if (-not $base) { $base = "https://github.com/TylerVigario/press/releases/download/v$version" }

    $here = (Get-Location).ProviderPath
    $press = Join-Path $here 'press'
    if ((Test-Path -LiteralPath (Join-Path $here 'press.toml')) -and (Test-Path -LiteralPath (Join-Path $here 'lib.typ'))) {
        throw "press: this is press's own directory; run the installer in the directory that holds press\"
    }
    if (Test-Path -LiteralPath (Join-Path $press '.git')) {
        throw 'press: .\press is a git checkout, such as the 0.1.0 submodule; remove it (git rm press) and run this again'
    }
    if ((Test-Path -LiteralPath $press) -and -not (Test-Path -LiteralPath (Join-Path $press 'press.toml') -PathType Leaf)) {
        throw 'press: .\press is not a press kit; move it aside and run this again'
    }

    # Windows PowerShell 5.1 on an older .NET offers no TLS 1.2 by default, and GitHub needs it.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Beside press\, so both moves below are renames on one volume.
    $tmp = Join-Path $here ('.press-install.' + [IO.Path]::GetRandomFileName())
    $old = Join-Path $tmp 'old'
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zip = Join-Path $tmp 'press.zip'
        try {
            Invoke-WebRequest -UseBasicParsing -Uri "$base/press.zip" -OutFile $zip
        } catch {
            throw "press: could not download $base/press.zip: $($_.Exception.Message)"
        }
        # .NET's SHA-256 rather than Get-FileHash: Windows PowerShell keeps that in a script
        # module, which a PowerShell 7 PSModulePath, inherited through cmd.exe as an npm script
        # run from PowerShell 7 inherits it, leaves it unable to find.
        $sha = [Security.Cryptography.SHA256]::Create()
        $stream = [IO.File]::OpenRead($zip)
        try { $got = -join ($sha.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) }
        finally { $stream.Dispose(); $sha.Dispose() }
        if ($got -ne $sum) {
            throw ("press: press.zip is not the archive press $version was released with; nothing changed`n" +
                "  expected $sum`n  got      $got")
        }
        # .NET's unzip rather than Expand-Archive: PowerShell 7 ships that in a script module,
        # which the Restricted execution policy refuses to load.
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [IO.Compression.ZipFile]::ExtractToDirectory($zip, $tmp)

        $was = ''
        if (Test-Path -LiteralPath $press) {
            $line = Select-String -LiteralPath (Join-Path $press 'press.toml') -Pattern '^version *= *"(.*)"$' |
                Select-Object -First 1
            if ($line) { $was = $line.Matches[0].Groups[1].Value }
            try { Move-Item -LiteralPath $press -Destination $old }
            catch { throw "press: could not move the old press\ aside; nothing changed: $($_.Exception.Message)" }
        }
        try { Move-Item -LiteralPath (Join-Path $tmp 'press') -Destination $press }
        catch { throw "press: could not put the new press\ in place; nothing changed: $($_.Exception.Message)" }
    } finally {
        # Puts the old copy back if it was moved aside and the new one is not in its place.
        if ((Test-Path -LiteralPath $old) -and -not (Test-Path -LiteralPath $press)) {
            Move-Item -LiteralPath $old -Destination $press
        }
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (-not $was) { Write-Host "press: installed $version in $press" }
    elseif ($was -eq $version) { Write-Host "press: reinstalled $version in $press" }
    else { Write-Host "press: installed $version in $press, replacing $was" }
}
