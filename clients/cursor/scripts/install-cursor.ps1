[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$PackageBranch,
    [switch]$ConfirmNoOtherInstallation,
    [string]$CursorHome = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.cursor')
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'update-lib.ps1')
if (-not $ConfirmNoOtherInstallation) {
    throw 'First uninstall the same-name marketplace/local plugin in Cursor, close Cursor, then pass -ConfirmNoOtherInstallation. No caches are deleted.'
}
if (Get-Process -Name Cursor -ErrorAction SilentlyContinue) { throw 'Fully exit Cursor before installing or repairing the workspace hook' }
$config = Get-CursorSubscription $PackageBranch
$bundle = Split-Path -Parent $PSScriptRoot
$indexBytes = [IO.File]::ReadAllBytes((Join-Path $bundle 'update-index.json'))
$index = [Text.Encoding]::UTF8.GetString($indexBytes) | ConvertFrom-Json
Assert-CursorBundle $bundle $index $config
$root = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA ('MetaverseAntennae/cursor-updates/' + $config.branchId)))
$CursorHome = [IO.Path]::GetFullPath($CursorHome)
Assert-CursorNoLinks $CursorHome
Assert-CursorNoLinks $root
if (Test-Path -LiteralPath (Join-Path $CursorHome 'plugins/local/metaverse-antennae')) {
    throw 'A same-name local plugin exists; remove it explicitly before migration'
}
$registrationGate = Open-CursorUpdateGate $CursorHome
try {
$null = New-Item -ItemType Directory -Force -Path $CursorHome
$hooksPath = Join-Path $CursorHome 'hooks.json'
Assert-CursorNoLinks $hooksPath
$before = if (Test-Path -LiteralPath $hooksPath) { [IO.File]::ReadAllBytes($hooksPath) } else { $null }
$hooks = if ($null -ne $before) { [Text.Encoding]::UTF8.GetString($before) | ConvertFrom-Json } else { [PSCustomObject]@{ version = 1; hooks = [PSCustomObject]@{} } }
if ($hooks.version -ne 1 -or $hooks.hooks -isnot [PSCustomObject]) { throw 'Unknown hooks.json structure; no registration changed' }
if ($hooks.hooks.PSObject.Properties['workspaceOpen'] -and $hooks.hooks.workspaceOpen -isnot [Array]) {
    throw 'workspaceOpen hooks must be an array; no registration changed'
}
$receiptPath = Join-Path $CursorHome 'antennae-workspace-install.json'
if (Test-Path -LiteralPath $receiptPath) {
    Assert-CursorIdentity (Read-CursorJson $receiptPath).subscription $config
}
if (Test-Path -LiteralPath $root) { Assert-CursorRoot $root $config }
else {
    $null = New-Item -ItemType Directory -Path $root
    Write-CursorJson (Join-Path $root 'subscription.json') $config
}
$gate = Open-CursorUpdateGate $root
try {
    # Repair/upgrade only our fixed bootstrap files; this operation is explicit,
    # with Cursor closed. Ordinary MCP releases need no installer rerun.
    $active = Install-CursorCandidate $root $config $indexBytes $bundle
    Invoke-CursorPrepare $active.plugin
    foreach ($name in @('workspace-open.ps1', 'update-lib.ps1', 'runtime-host.cs')) {
        $destination = Join-Path $root $name
        Assert-CursorNoLinks $destination
        [IO.File]::WriteAllBytes($destination, [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $name)))
    }
    $escaped = (Join-Path $root 'workspace-open.ps1').Replace("'", "''")
    $expression = "& '$escaped'"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($expression))
    $command = 'powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ' + $encoded
    $existing = @()
    if ($hooks.hooks.PSObject.Properties['workspaceOpen']) { $existing = @($hooks.hooks.workspaceOpen) }
    # Do not add undocumented fields to the Cursor hook schema. The installation
    # receipt owns the exact command, enabling idempotent registration.
    if (Test-Path -LiteralPath $receiptPath) {
        $receipt = Read-CursorJson $receiptPath
        Assert-CursorIdentity $receipt.subscription $config
        if ($receipt.command -cne $command) { throw 'Existing bootstrap registration differs' }
    }
    $remaining = @($existing | Where-Object { -not $_.PSObject.Properties['command'] -or $_.command -cne $command })
    $hooks.hooks | Add-Member -Force NoteProperty workspaceOpen (@($remaining) + @(@{ command = $command; timeout = 480 }))
    # Reject a concurrent user edit rather than overwriting it.
    $now = if (Test-Path -LiteralPath $hooksPath) { [IO.File]::ReadAllBytes($hooksPath) } else { $null }
    if (($null -eq $before) -ne ($null -eq $now) -or
        ($null -ne $before -and (Get-CursorDigest $before) -cne (Get-CursorDigest $now))) { throw 'hooks.json changed during installation' }
    $backup = Join-Path $root 'hooks-before-install.json'
    if ($null -ne $before -and -not (Test-Path -LiteralPath $backup)) { [IO.File]::WriteAllBytes($backup, $before) }
    Write-CursorJson $receiptPath @{ subscription = $config; command = $command }
    Write-CursorJson $hooksPath $hooks
    [Console]::Out.WriteLine('Installed ' + $active.index.version + '. Open a project in Cursor; automatic updates use workspaceOpen, not the personal marketplace.')
} finally { $gate.ReleaseMutex(); $gate.Dispose() }
} finally { $registrationGate.ReleaseMutex(); $registrationGate.Dispose() }
