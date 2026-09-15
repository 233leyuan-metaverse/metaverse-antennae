[CmdletBinding()]
param([switch]$PrepareOnly, [string]$CacheRoot = '')

# This is a packaging bootstrap, not a second MCP server. stdout belongs to MCP.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$PluginRoot = Split-Path -Parent $PSScriptRoot
$Spec = Get-Content -Raw -LiteralPath (Join-Path $PluginRoot 'runtime-lock.json') | ConvertFrom-Json
$Registry = 'https://api-web-registry.metaapp.cn'
$SlotLease = $null
$Gate = $null
$GateHeld = $false
$StageRoot = $null

function Assert-NoLinks([string]$Path) {
    $probe = [IO.Path]::GetFullPath($Path)
    while ($probe) {
        if (Test-Path -LiteralPath $probe) {
            if ((Get-Item -Force -LiteralPath $probe).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Cache/plugin paths cannot follow links: $probe"
            }
        }
        $parent = [IO.Directory]::GetParent($probe)
        if ($null -eq $parent) { break }
        $probe = $parent.FullName
    }
}

function Get-PackagePath([string]$Root, [string]$Relative) {
    if ($Relative -notmatch '^[^\\:]+$' -or $Relative.StartsWith('/') -or
        @($Relative.Split('/') | Where-Object { $_ -eq '' -or $_ -eq '.' -or $_ -eq '..' -or
        $_ -match '[. ]$|^(?i:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)' }).Count) {
        throw 'Invalid package inventory path'
    }
    $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not $full.StartsWith([IO.Path]::GetFullPath($Root).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Package inventory escapes its root'
    }
    return $full
}

function Get-Sha256([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function Assert-Payload([string]$Payload) {
    Assert-NoLinks $Payload
    $actual = @(Get-ChildItem -Force -Recurse -LiteralPath $Payload)
    if (@($actual | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Payload contains links' }
    $expected = @($Spec.files.PSObject.Properties)
    if (@($actual | Where-Object { -not $_.PSIsContainer }).Count -ne $expected.Count) { throw 'Payload file inventory differs' }
    foreach ($entry in $expected) {
        $path = Get-PackagePath $Payload $entry.Name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-Sha256 $path) -cne $entry.Value) {
            throw "Payload integrity mismatch: $($entry.Name)"
        }
    }
    $package = Get-Content -Raw -LiteralPath (Join-Path $Payload 'package.json') | ConvertFrom-Json
    if ($package.name -cne $Spec.package -or $package.version -cne $Spec.version) { throw 'Payload identity differs' }
}

function Open-SlotLease([string]$Slot, [bool]$Exclusive) {
    $path = Join-Path $CacheRoot ($Slot + '.lease')
    Assert-NoLinks $path
    $share = if ($Exclusive) { [IO.FileShare]::None } else { [IO.FileShare]::ReadWrite }
    return [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, $share)
}

function Remove-OwnedDirectory([string]$Path, [bool]$IsStage = $false) {
    $full = [IO.Path]::GetFullPath($Path)
    if ([IO.Directory]::GetParent($full).FullName -cne $CacheRoot -or
        (-not $IsStage -and [IO.Path]::GetFileName($full) -notin @('slot-a', 'slot-b')) -or
        ($IsStage -and [IO.Path]::GetFileName($full) -notmatch '^stage-[a-f0-9]{32}$')) { throw 'Unsafe cleanup target' }
    Assert-NoLinks $full
    if (-not (Test-Path -LiteralPath $full)) { return }
    $marker = Get-Content -Raw -LiteralPath (Join-Path $full 'owner.json') | ConvertFrom-Json
    if ($marker.package -cne $Spec.package -or $marker.branch -cne $Spec.packageBranch) { throw 'Refusing to replace an unowned cache directory' }
    if (@(Get-ChildItem -Force -Recurse -LiteralPath $full | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
        throw 'Refusing recursive cleanup through a link'
    }
    Remove-Item -LiteralPath $full -Force -Recurse
}

function Resolve-NpmToolchain {
    # Cursor prepends its own standalone node.exe to PATH. Select the first
    # complete Node/npm installation, not merely the first Node executable.
    foreach ($command in @(Get-Command node.exe -CommandType Application -All -ErrorAction SilentlyContinue)) {
        $node = $command.Source
        $npm = Join-Path (Split-Path -Parent $node) 'node_modules/npm/bin/npm-cli.js'
        if (Test-Path -LiteralPath $npm -PathType Leaf) {
            return [PSCustomObject]@{ Node = $node; Npm = $npm }
        }
    }
    throw 'No Node.js installation with npm found on PATH; install Node.js with npm and fully restart Cursor'
}

function Install-LockedPayload([string]$Stage) {
    # Fail before downloading if no complete toolchain is available. Cached
    # payloads bypass this function and still need neither Node nor npm.
    $toolchain = Resolve-NpmToolchain
    [Console]::Error.WriteLine('[antennae] Downloading locked runtime ' + $Spec.version)
    $archive = Join-Path $Stage 'payload.tgz'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $request = [Net.HttpWebRequest]::Create([uri]$Spec.tarball)
    $request.AllowAutoRedirect = $false
    $request.Timeout = 60000
    $request.ReadWriteTimeout = 60000
    $response = $request.GetResponse()
    try {
        if ([int]$response.StatusCode -ne 200) { throw 'Package download did not return HTTP 200' }
        $inputStream = $response.GetResponseStream()
        $outputStream = [IO.File]::Create($archive)
        try {
            $buffer = New-Object byte[] 65536
            $total = 0
            while (($count = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $total += $count
                if ($total -gt 20971520) { throw 'Package exceeds 20 MiB download budget' }
                $outputStream.Write($buffer, 0, $count)
            }
        } finally { $outputStream.Dispose(); $inputStream.Dispose() }
    } finally { $response.Dispose() }
    $stream = [IO.File]::OpenRead($archive)
    $sha = [Security.Cryptography.SHA512]::Create()
    try { $integrity = 'sha512-' + [Convert]::ToBase64String($sha.ComputeHash($stream)) }
    finally { $sha.Dispose(); $stream.Dispose() }
    if ($integrity -cne $Spec.integrity) { throw 'Downloaded package SHA-512 differs from runtime-lock.json' }

    # Use the existing npm tool only to safely extract this verified local package.
    # Empty configs + offline + ignore-scripts: no publisher credentials or install hooks.
    $emptyUser = Join-Path $Stage 'empty-user.npmrc'
    $emptyGlobal = Join-Path $Stage 'empty-global.npmrc'
    [IO.File]::WriteAllText($emptyUser, '')
    [IO.File]::WriteAllText($emptyGlobal, '')
    $arguments = @($toolchain.Npm, 'install', $archive, '--prefix', $Stage, '--ignore-scripts', '--offline',
        '--no-audit', '--no-fund', '--no-save', '--package-lock=false', '--global=false',
        ('--registry=' + $Registry), ('--userconfig=' + $emptyUser), ('--globalconfig=' + $emptyGlobal),
        ('--cache=' + (Join-Path $Stage 'npm-cache')))
    $code = [AntennaeCursorHost]::Install($toolchain.Node, $arguments, $Stage, (Join-Path $Stage 'npm.log'))
    if ($code -ne 0) { throw "npm extraction failed ($code); no installed slot was changed" }
    $payload = Join-Path $Stage ('node_modules/' + $Spec.package)
    Assert-Payload $payload
    return $payload
}

try {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or -not [Environment]::Is64BitProcess) {
        throw 'The current payload requires Windows x64'
    }
    Assert-NoLinks $PluginRoot
    if ($Spec.schemaVersion -ne 1 -or $Spec.platform -cne 'win32-x64' -or $Spec.registry -cne $Registry -or
        $Spec.version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or
        $Spec.branchId -notmatch '^[a-z0-9_-]{1,80}$' -or
        $Spec.branchId -cne ($Spec.packageBranch.ToLowerInvariant() -replace '[^a-z0-9_-]', '_') -or
        $Spec.packageBranch -notmatch '^test/' -or
        $Spec.package -cne ('@mta/metaverse-antennae-dev-' + $Spec.branchId) -or
        $Spec.integrity -notmatch '^sha512-[A-Za-z0-9+/]{86}==$') { throw 'Invalid Cursor runtime lock' }
    $url = [uri]$Spec.tarball
    if ($url.Scheme -cne 'https' -or $url.Authority -cne 'api-web-registry.metaapp.cn' -or
        $url.UserInfo -or $url.Query -or $url.Fragment) { throw 'Unapproved package download origin' }
    $entries = @($Spec.files.PSObject.Properties)
    if ($entries.Count -eq 0 -or $entries.Count -gt 5000) { throw 'Invalid package inventory size' }
    foreach ($entry in $entries) {
        if ($entry.Value -notmatch '^[a-f0-9]{64}$') { throw 'Invalid package file digest' }
        $null = Get-PackagePath $PluginRoot $entry.Name
        if ($entry.Name.StartsWith('skills/')) {
            $skill = Get-PackagePath $PluginRoot $entry.Name
            if (-not (Test-Path -LiteralPath $skill -PathType Leaf) -or
                (Get-Sha256 $skill) -cne $entry.Value) {
                throw 'Cursor Skills do not match the locked runtime; reinstall the matching wrapper'
            }
        }
    }
    if (-not $CacheRoot) { $CacheRoot = Join-Path $env:LOCALAPPDATA ('MetaverseAntennae/cursor/' + $Spec.branchId) }
    if (-not [IO.Path]::IsPathRooted($CacheRoot)) { throw 'CacheRoot must be absolute' }
    $CacheRoot = [IO.Path]::GetFullPath($CacheRoot).TrimEnd('\')
    if (-not [IO.Directory]::GetParent($CacheRoot)) { throw 'CacheRoot cannot be a volume root' }
    Assert-NoLinks $CacheRoot
    $null = New-Item -ItemType Directory -Force -Path $CacheRoot
    Add-Type -Path (Join-Path $PSScriptRoot 'runtime-host.cs')
    $nameHash = [Security.Cryptography.SHA256]::Create()
    try { $key = [BitConverter]::ToString($nameHash.ComputeHash([Text.Encoding]::UTF8.GetBytes($CacheRoot.ToLowerInvariant()))).Replace('-', '') }
    finally { $nameHash.Dispose() }
    $Gate = New-Object Threading.Mutex($false, ('Local\AntennaeCursor-' + $key))
    try { $GateHeld = $Gate.WaitOne(120000) } catch [Threading.AbandonedMutexException] { $GateHeld = $true }
    if (-not $GateHeld) { throw 'Timed out waiting for another Cursor runtime install' }
    # Only this bootstrap creates owner-marked stage directories. Holding the
    # install mutex means a previous one is abandoned, including after a crash.
    foreach ($oldStage in @(Get-ChildItem -Force -Directory -LiteralPath $CacheRoot | Where-Object { $_.Name -match '^stage-[a-f0-9]{32}$' })) {
        if (Test-Path -LiteralPath (Join-Path $oldStage.FullName 'owner.json')) {
            Remove-OwnedDirectory $oldStage.FullName $true
        }
    }
    $selected = $null
    foreach ($slot in @('slot-a', 'slot-b')) {
        $path = Join-Path $CacheRoot $slot
        Assert-NoLinks $path
        if (Test-Path -LiteralPath (Join-Path $path 'owner.json')) {
            $owner = Get-Content -Raw -LiteralPath (Join-Path $path 'owner.json') | ConvertFrom-Json
            if ($owner.package -cne $Spec.package -or $owner.branch -cne $Spec.packageBranch) { throw 'Cache belongs to another publication' }
            if ($owner.integrity -ceq $Spec.integrity) {
                Assert-Payload (Join-Path $path 'payload')
                $selected = $path
                $SlotLease = Open-SlotLease $slot $false
                break
            }
        } elseif (Test-Path -LiteralPath $path) {
            throw 'Refusing to use an unowned runtime slot'
        }
    }
    if (-not $selected) {
        $replacement = $null
        # Prefer the empty/older slot, retaining the most recent working payload.
        $candidates = @('slot-a', 'slot-b') | Sort-Object {
            $candidate = Join-Path $CacheRoot $_
            if (Test-Path -LiteralPath $candidate) { (Get-Item -LiteralPath $candidate).LastWriteTimeUtc }
            else { [DateTime]::MinValue }
        }
        foreach ($slot in $candidates) {
            try { $SlotLease = Open-SlotLease $slot $true; $replacement = $slot; break }
            catch [IO.IOException] { continue }
        }
        if (-not $replacement) { throw 'Both runtime slots are in use; close older Cursor MCP sessions before upgrading' }
        $StageRoot = Join-Path $CacheRoot ('stage-' + [Guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $StageRoot
        @{ package = $Spec.package; branch = $Spec.packageBranch } | ConvertTo-Json |
            Set-Content -LiteralPath (Join-Path $StageRoot 'owner.json') -Encoding UTF8
        $payload = Install-LockedPayload $StageRoot
        $ready = Join-Path $StageRoot 'ready'
        $null = New-Item -ItemType Directory -Path $ready
        Move-Item -LiteralPath $payload -Destination (Join-Path $ready 'payload')
        @{ package = $Spec.package; branch = $Spec.packageBranch; version = $Spec.version; integrity = $Spec.integrity } |
            ConvertTo-Json | Set-Content -LiteralPath (Join-Path $ready 'owner.json') -Encoding UTF8
        $selected = Join-Path $CacheRoot $replacement
        $previous = Join-Path $StageRoot 'previous'
        if (Test-Path -LiteralPath $selected) {
            # Exact direct-child slot was validated above, is owned, and its
            # exclusive lease excludes running processes. Retain it for rollback.
            Assert-NoLinks $selected
            Move-Item -LiteralPath $selected -Destination $previous
        }
        try { Move-Item -LiteralPath $ready -Destination $selected }
        catch {
            if (Test-Path -LiteralPath $previous) { Move-Item -LiteralPath $previous -Destination $selected }
            throw
        }
        Remove-OwnedDirectory $StageRoot $true
        $StageRoot = $null
        $SlotLease.Dispose()
        $SlotLease = Open-SlotLease $replacement $false
    }
    $Gate.ReleaseMutex(); $GateHeld = $false
    $exe = Join-Path $selected 'payload/runtime/metaverse-antennae-mcp/metaverse-antennae-mcp.exe'
    if ($PrepareOnly) {
        @{ package = $Spec.package; version = $Spec.version; executable = $exe; slot = $selected } | ConvertTo-Json -Compress
    } else {
        [Console]::Error.WriteLine('[antennae] Starting locked runtime ' + $Spec.version)
        $exitCode = [AntennaeCursorHost]::Run($exe, (Split-Path -Parent $exe))
        if ($exitCode -ne 0) { throw "MCP exited with code $exitCode" }
    }
} catch {
    [Console]::Error.WriteLine('[antennae] ' + $_.Exception.Message)
    exit 1
} finally {
    if ($StageRoot -and (Test-Path -LiteralPath $StageRoot)) { Remove-OwnedDirectory $StageRoot $true }
    if ($SlotLease) { $SlotLease.Dispose() }
    if ($GateHeld) { $Gate.ReleaseMutex() }
    if ($Gate) { $Gate.Dispose() }
}
