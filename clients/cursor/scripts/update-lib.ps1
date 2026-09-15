# Distribution-only library. No MCP operations, client registration or network on import.
Set-StrictMode -Version Latest

function Assert-CursorNoLinks([string]$Path) {
    $probe = [IO.Path]::GetFullPath($Path)
    while ($probe) {
        if ((Test-Path -LiteralPath $probe) -and
            ((Get-Item -Force -LiteralPath $probe).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Refusing linked update path: $probe"
        }
        $parent = [IO.Directory]::GetParent($probe)
        if ($null -eq $parent) { break }
        $probe = $parent.FullName
    }
}

function Get-CursorDigest([byte[]]$Bytes) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($hash.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $hash.Dispose() }
}

function Read-CursorJson([string]$Path) {
    Assert-CursorNoLinks $Path
    if ((Get-Item -LiteralPath $Path).Length -gt 262144) { throw 'Oversized update metadata' }
    return [IO.File]::ReadAllText($Path) | ConvertFrom-Json
}

function Write-CursorJson([string]$Path, $Value) {
    Assert-CursorNoLinks $Path
    $temporary = $Path + '.pending'
    Assert-CursorNoLinks $temporary
    [IO.File]::WriteAllText($temporary, ($Value | ConvertTo-Json -Depth 40), (New-Object Text.UTF8Encoding($false)))
    # Callers hold the installation mutex. The pointer/config is never half JSON.
    if (Test-Path -LiteralPath $Path) { [IO.File]::Replace($temporary, $Path, [NullString]::Value) }
    else { [IO.File]::Move($temporary, $Path) }
}

function Get-CursorSubscription([string]$Branch) {
    $id = $Branch.ToLowerInvariant() -replace '[^a-z0-9_-]', '_'
    if (-not $Branch.StartsWith('test/', [StringComparison]::Ordinal) -or
        $Branch -match '[\x00-\x20\\]' -or $id.Length -gt 80 -or $id -notmatch '[a-z0-9]') {
        throw 'Only explicitly selected test/ package branches are enabled in this pilot'
    }
    return [PSCustomObject]@{
        schemaVersion = 1; repository = '233leyuan-metaverse/metaverse-antennae'
        packageBranch = $Branch; branchId = $id; package = '@mta/metaverse-antennae-dev-' + $id
    }
}

function Assert-CursorIdentity($Value, $Config) {
    foreach ($key in @('schemaVersion', 'repository', 'packageBranch', 'branchId', 'package')) {
        if ($Value.$key -cne $Config.$key) { throw "Update identity mismatch: $key" }
    }
}

function Assert-CursorRoot([string]$Root, $Config) {
    Assert-CursorNoLinks $Root
    $expected = Join-Path $env:LOCALAPPDATA ('MetaverseAntennae/cursor-updates/' + $Config.branchId)
    if ([IO.Path]::GetFullPath($Root).TrimEnd('\') -ine [IO.Path]::GetFullPath($expected).TrimEnd('\')) {
        throw 'Update root is outside its fixed installation location'
    }
    Assert-CursorIdentity (Read-CursorJson (Join-Path $Root 'subscription.json')) $Config
}

function Get-CursorBundlePath([string]$Root, [string]$Relative) {
    if ($Relative -notmatch '^[a-zA-Z0-9_.\-/]+$' -or $Relative.StartsWith('/') -or
        @($Relative.Split('/') | Where-Object { $_ -eq '' -or $_ -eq '.' -or $_ -eq '..' -or
            $_ -match '[.]$|^(?i:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)' }).Count) {
        throw 'Unsafe wrapper inventory path'
    }
    $path = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not $path.StartsWith([IO.Path]::GetFullPath($Root).TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Wrapper inventory escapes root'
    }
    Assert-CursorNoLinks $path
    return $path
}

function Assert-CursorIndex($Index, $Config) {
    Assert-CursorIdentity $Index $Config
    if ($Index.bootstrapVersion -ne 1 -or $Index.version -notmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
        throw 'Unsupported update protocol/version; installer upgrade may be required'
    }
    $entries = @($Index.files.PSObject.Properties)
    if ($entries.Count -lt 7 -or $entries.Count -gt 256) { throw 'Invalid wrapper inventory size' }
    $names = @{}
    foreach ($entry in $entries) {
        $null = Get-CursorBundlePath ([IO.Path]::GetTempPath()) $entry.Name
        if ($names.ContainsKey($entry.Name) -or $entry.Name -ieq 'update-index.json' -or $entry.Value -notmatch '^[a-f0-9]{64}$') {
            throw 'Duplicate, recursive or invalid wrapper inventory'
        }
        $names[$entry.Name] = $true
    }
    foreach ($name in @('.cursor-plugin/plugin.json', 'mcp.json', 'runtime-lock.json',
                        'scripts/start-mcp.ps1', 'scripts/runtime-host.cs',
                        'scripts/workspace-open.ps1', 'scripts/update-lib.ps1')) {
        if (-not $names.ContainsKey($name)) { throw "Incomplete wrapper: $name" }
    }
}

function Assert-CursorBundle([string]$Plugin, $Index, $Config) {
    Assert-CursorIndex $Index $Config
    Assert-CursorNoLinks $Plugin
    $actual = @(Get-ChildItem -Force -Recurse -LiteralPath $Plugin)
    if (@($actual | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Linked wrapper content' }
    if (@($actual | Where-Object { -not $_.PSIsContainer }).Count -ne @($Index.files.PSObject.Properties).Count + 1) {
        throw 'Wrapper has missing or unexpected files'
    }
    $total = 0
    foreach ($entry in $Index.files.PSObject.Properties) {
        $file = Get-CursorBundlePath $Plugin $entry.Name
        $total += (Get-Item -LiteralPath $file).Length
        if ($total -gt 2097152 -or (Get-CursorDigest ([IO.File]::ReadAllBytes($file))) -cne $entry.Value) {
            throw "Wrapper integrity mismatch: $($entry.Name)"
        }
    }
    $manifest = Read-CursorJson (Join-Path $Plugin '.cursor-plugin/plugin.json')
    $lock = Read-CursorJson (Join-Path $Plugin 'runtime-lock.json')
    if ($manifest.name -cne 'metaverse-antennae' -or $manifest.version -cne $Index.version -or
        $lock.version -cne $Index.version -or $lock.package -cne $Config.package -or
        $lock.packageBranch -cne $Config.packageBranch -or $lock.branchId -cne $Config.branchId -or
        $lock.registry -cne 'https://api-web-registry.metaapp.cn' -or $lock.platform -cne 'win32-x64') {
        throw 'Skills/plugin/runtime release identity differs'
    }
    foreach ($entry in $lock.files.PSObject.Properties) {
        if ($entry.Name.StartsWith('skills/') -and $Index.files.($entry.Name) -cne $entry.Value) {
            throw 'Skills differ from locked npm release'
        }
    }
    foreach ($entry in $Index.files.PSObject.Properties) {
        if ($entry.Name.StartsWith('skills/') -and -not $lock.files.PSObject.Properties[$entry.Name]) {
            throw 'Unexpected Skills outside the locked npm release'
        }
    }
}

function Get-CursorRemoteBytes([uri]$Uri, [int]$MaxBytes) {
    if ($Uri.Scheme -cne 'https' -or $Uri.Authority -cne 'raw.githubusercontent.com' -or $Uri.UserInfo -or $Uri.Fragment -or
        -not $Uri.AbsolutePath.StartsWith('/233leyuan-metaverse/metaverse-antennae/refs/heads/', [StringComparison]::Ordinal)) {
        throw 'Unapproved wrapper download origin'
    }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $request = [Net.HttpWebRequest]::Create($Uri)
    $request.AllowAutoRedirect = $false
    $request.Timeout = 10000; $request.ReadWriteTimeout = 10000
    $request.Headers['Cache-Control'] = 'no-cache'
    # Anonymous download: never inherit npm/publisher tokens or Git credentials.
    $response = $request.GetResponse()
    try {
        if ([int]$response.StatusCode -ne 200) { throw 'Wrapper download did not return HTTP 200' }
        $stream = $response.GetResponseStream(); $memory = New-Object IO.MemoryStream
        try {
            $buffer = New-Object byte[] 16384
            $watch = [Diagnostics.Stopwatch]::StartNew()
            while (($count = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                if ($memory.Length + $count -gt $MaxBytes -or $watch.Elapsed.TotalSeconds -gt 15) { throw 'Wrapper download exceeded budget' }
                $memory.Write($buffer, 0, $count)
            }
            return ,$memory.ToArray()
        } finally { $stream.Dispose(); $memory.Dispose() }
    } finally { $response.Dispose() }
}

function Get-CursorRemoteUrl($Config, [string]$Relative, [string]$CacheKey) {
    $null = Get-CursorBundlePath ([IO.Path]::GetTempPath()) $Relative
    $branch = ($Config.packageBranch.Split('/') | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
    return [uri]('https://raw.githubusercontent.com/' + $Config.repository + '/refs/heads/' + $branch +
        '/clients/cursor/' + $Relative + '?antennae=' + [uri]::EscapeDataString($CacheKey))
}

function Invoke-CursorPrepare([string]$Plugin) {
    if (-not ('AntennaeCursorHost' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'runtime-host.cs') }
    $log = Join-Path (Split-Path -Parent $Plugin) 'prepare.log'
    $code = [AntennaeCursorHost]::Install((Join-Path $PSHOME 'powershell.exe'),
        @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File',
          (Join-Path $Plugin 'scripts/start-mcp.ps1'), '-PrepareOnly'), $Plugin, $log)
    if ($code -ne 0) { throw "Runtime preparation failed; see $log" }
    # Verify the child prepared the exact version before exposing any Skills.
    $line = @([IO.File]::ReadAllLines($log) | Where-Object { $_.StartsWith('{') })
    if ($line.Count -ne 1) { throw 'Runtime preparation did not return one result' }
    $result = $line[0] | ConvertFrom-Json
    if ($result.version -cne (Read-CursorJson (Join-Path $Plugin 'runtime-lock.json')).version) {
        throw 'Prepared runtime version differs'
    }
}

function Get-CursorConsumer {
    $next = $PID; $consumer = $null
    for ($depth = 0; $depth -lt 24 -and $next -gt 0; $depth++) {
        $item = Get-CimInstance Win32_Process -Filter "ProcessId=$next" -ErrorAction Stop
        if ($null -eq $item) { break }
        if ($item.Name -ieq 'Cursor.exe') {
            $process = Get-Process -Id $next -ErrorAction Stop
            $consumer = [PSCustomObject]@{ pid = $next; started = $process.StartTime.ToUniversalTime().Ticks.ToString() }
        }
        if ($item.ParentProcessId -eq $next) { break }
        $next = [int]$item.ParentProcessId
    }
    if ($null -eq $consumer) { throw 'Cannot identify Cursor desktop lifetime; no plugin files will be replaced' }
    return $consumer
}

function Test-CursorConsumer($Consumer) {
    try {
        $process = Get-Process -Id $Consumer.pid -ErrorAction Stop
        return $process.StartTime.ToUniversalTime().Ticks.ToString() -ceq $Consumer.started
    } catch [Microsoft.PowerShell.Commands.ProcessCommandException] { return $false }
    catch { return $true } # Unknown process state protects data rather than enabling deletion.
}

function Get-CursorLiveConsumers([string]$Slot) {
    $file = Join-Path $Slot 'consumers.json'
    if (-not (Test-Path -LiteralPath $file)) { return @() }
    $list = (Read-CursorJson $file).items
    return @($list | Where-Object { Test-CursorConsumer $_ })
}

function Remove-CursorOwnedDirectory([string]$Root, [string]$Path, $Config) {
    Assert-CursorRoot $Root $Config
    $full = [IO.Path]::GetFullPath($Path)
    if ([IO.Directory]::GetParent($full).FullName -ine [IO.Path]::GetFullPath($Root).TrimEnd('\') -or
        [IO.Path]::GetFileName($full) -notmatch '^(slot-[ab]|stage-[a-f0-9]{32})$') { throw 'Unsafe update cleanup target' }
    Assert-CursorNoLinks $full
    if (-not (Test-Path -LiteralPath $full)) { return }
    Assert-CursorIdentity (Read-CursorJson (Join-Path $full 'owner.json')) $Config
    if (@(Get-CursorLiveConsumers $full).Count) { throw 'Cursor is still using this wrapper slot' }
    if (@(Get-ChildItem -Force -Recurse -LiteralPath $full | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
        throw 'Refusing cleanup through links'
    }
    Remove-Item -Force -Recurse -LiteralPath $full
}

function Get-CursorRelease([string]$Root, $Config, [string]$Name) {
    if ($Name -notin @('slot-a', 'slot-b')) { throw 'Invalid wrapper slot' }
    $slot = Join-Path $Root $Name
    $owner = Read-CursorJson (Join-Path $slot 'owner.json')
    Assert-CursorIdentity $owner $Config
    if ($owner.indexDigest -notmatch '^[a-f0-9]{64}$') { throw 'Invalid cached release receipt' }
    $plugin = Join-Path $slot 'plugin'
    $indexPath = Join-Path $plugin 'update-index.json'
    Assert-CursorNoLinks $indexPath
    if ((Get-CursorDigest ([IO.File]::ReadAllBytes($indexPath))) -cne $owner.indexDigest) { throw 'Cached update index changed' }
    $index = Read-CursorJson $indexPath
    Assert-CursorBundle $plugin $index $Config
    return [PSCustomObject]@{ plugin = $plugin; slot = $slot; index = $index; digest = $owner.indexDigest }
}

function Get-CursorActive([string]$Root, $Config) {
    $file = Join-Path $Root 'active.json'
    if (-not (Test-Path -LiteralPath $file)) { return $null }
    $active = Read-CursorJson $file
    $release = Get-CursorRelease $Root $Config $active.slot
    if ($release.digest -cne $active.indexDigest) { throw 'Active pointer differs from release receipt' }
    return $release
}

function Install-CursorCandidate([string]$Root, $Config, [byte[]]$IndexBytes, [string]$Bundle = '') {
    Assert-CursorRoot $Root $Config
    $index = [Text.Encoding]::UTF8.GetString($IndexBytes) | ConvertFrom-Json
    Assert-CursorIndex $index $Config
    $digest = Get-CursorDigest $IndexBytes
    $active = Get-CursorActive $Root $Config
    if ($active) {
        if ([version]$index.version -lt [version]$active.index.version) { throw 'Refusing automatic downgrade' }
        if ($index.version -ceq $active.index.version) {
            if ($digest -cne $active.digest) { throw 'Same version has different wrapper bytes; publish a new version' }
            return $active
        }
    }
    $replacement = $null
    foreach ($name in @('slot-a', 'slot-b')) {
        $slot = Join-Path $Root $name
        if ($active -and $slot -ieq $active.slot) { continue }
        if (-not (Test-Path -LiteralPath $slot) -or @(Get-CursorLiveConsumers $slot).Count -eq 0) { $replacement = $slot; break }
    }
    if (-not $replacement) { throw 'Both releases are in use; fully exit Cursor before the next update' }
    $stage = Join-Path $Root ('stage-' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $stage
    Write-CursorJson (Join-Path $stage 'owner.json') $Config
    try {
        $plugin = Join-Path $stage 'plugin'
        $null = New-Item -ItemType Directory -Path $plugin
        [IO.File]::WriteAllBytes((Join-Path $plugin 'update-index.json'), $IndexBytes)
        $total = 0; $watch = [Diagnostics.Stopwatch]::StartNew()
        foreach ($entry in $index.files.PSObject.Properties) {
            if ($watch.Elapsed.TotalSeconds -gt 60) { throw 'Wrapper update exceeded total download budget' }
            if ($Bundle) { $bytes = [IO.File]::ReadAllBytes((Get-CursorBundlePath $Bundle $entry.Name)) }
            else { $bytes = Get-CursorRemoteBytes (Get-CursorRemoteUrl $Config $entry.Name $entry.Value) (2097152 - $total) }
            $total += $bytes.Length
            if ($total -gt 2097152 -or (Get-CursorDigest $bytes) -cne $entry.Value) { throw "Downloaded wrapper integrity mismatch: $($entry.Name)" }
            $file = Get-CursorBundlePath $plugin $entry.Name
            $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $file)
            [IO.File]::WriteAllBytes($file, $bytes)
        }
        Assert-CursorBundle $plugin $index $Config
        Invoke-CursorPrepare $plugin
        $owner = $Config | ConvertTo-Json | ConvertFrom-Json
        $owner | Add-Member NoteProperty indexDigest $digest
        Write-CursorJson (Join-Path $stage 'owner.json') $owner
        # Preserve the current release; only the unreferenced alternate slot is reclaimed.
        Remove-CursorOwnedDirectory $Root $replacement $Config
        [IO.Directory]::Move($stage, $replacement)
        $stage = $null
        Write-CursorJson (Join-Path $Root 'active.json') @{ slot = [IO.Path]::GetFileName($replacement); indexDigest = $digest }
        return Get-CursorActive $Root $Config
    } finally { if ($stage) { Remove-CursorOwnedDirectory $Root $stage $Config } }
}

function Open-CursorUpdateGate([string]$Root) {
    $key = Get-CursorDigest ([Text.Encoding]::UTF8.GetBytes([IO.Path]::GetFullPath($Root).ToLowerInvariant()))
    $gate = New-Object Threading.Mutex($false, ('Local\AntennaeCursorUpdate-' + $key))
    try {
        $held = $false
        try { $held = $gate.WaitOne(240000) } catch [Threading.AbandonedMutexException] { $held = $true }
        if (-not $held) { throw 'Another Cursor update is busy; retry opening the workspace' }
        return $gate
    } catch { $gate.Dispose(); throw }
}

function Sync-CursorWorkspace([string]$Root, $Config, $Consumer) {
    Assert-CursorRoot $Root $Config
    $gate = Open-CursorUpdateGate $Root
    try {
        foreach ($old in @(Get-ChildItem -Force -Directory -LiteralPath $Root | Where-Object { $_.Name -match '^stage-[a-f0-9]{32}$' })) {
            if (Test-Path -LiteralPath (Join-Path $old.FullName 'owner.json')) { Remove-CursorOwnedDirectory $Root $old.FullName $Config }
        }
        # workspaceOpen also runs on folder changes. Cursor adds returned paths
        # rather than removing the prior path, so pin one complete release for
        # the entire desktop process. Only a full restart selects a new release.
        foreach ($name in @('slot-a', 'slot-b')) {
            $same = @(Get-CursorLiveConsumers (Join-Path $Root $name) | Where-Object {
                $_.pid -eq $Consumer.pid -and $_.started -ceq $Consumer.started
            })
            if ($same.Count) {
                $pinned = Get-CursorRelease $Root $Config $name
                Invoke-CursorPrepare $pinned.plugin
                return $pinned.plugin
            }
        }
        $active = Get-CursorActive $Root $Config
        $status = 'current'; $reason = ''
        try {
            $bytes = Get-CursorRemoteBytes (Get-CursorRemoteUrl $Config 'update-index.json' ([DateTime]::UtcNow.ToString('yyyyMMddHHmm'))) 262144
            $selected = Install-CursorCandidate $Root $Config $bytes
            if (-not $active -or $selected.digest -cne $active.digest) { $status = 'updated' }
        } catch {
            if (-not $active) { throw }
            $selected = $active; $status = 'retained'; $reason = $_.Exception.Message
            [Console]::Error.WriteLine('[antennae-update] Keeping verified ' + $active.index.version + ': ' + $reason)
        }
        if ($status -ne 'updated') { Invoke-CursorPrepare $selected.plugin }
        $consumers = @(Get-CursorLiveConsumers $selected.slot | Where-Object { $_.pid -ne $Consumer.pid -or $_.started -cne $Consumer.started })
        if ($consumers.Count -ge 32) { throw 'Too many concurrent Cursor instances' }
        Write-CursorJson (Join-Path $selected.slot 'consumers.json') @{ items = @($consumers) + @($Consumer) }
        Write-CursorJson (Join-Path $Root 'last-update.json') @{
            checkedAt = [DateTime]::UtcNow.ToString('o'); status = $status; version = $selected.index.version; reason = $reason
        }
        return $selected.plugin
    } finally { $gate.ReleaseMutex(); $gate.Dispose() }
}
