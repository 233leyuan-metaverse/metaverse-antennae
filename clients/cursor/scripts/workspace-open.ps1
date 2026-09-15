[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Console]::InputEncoding = New-Object Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
# Installed once as a user-level hook, not inside a marketplace plugin. No event
# payload (email/workspace paths) is sent to GitHub, npm, logs or telemetry.
try {
    $inputText = [Console]::In.ReadToEnd()
    if ($inputText.Length -gt 65536) { throw 'Oversized workspace event' }
    $event = $inputText | ConvertFrom-Json
    if ($event.hook_event_name -cne 'workspaceOpen' -or @($event.workspace_roots).Count -eq 0) {
        [Console]::Out.WriteLine('{"pluginPaths":[]}'); exit 0
    }
    . (Join-Path $PSScriptRoot 'update-lib.ps1')
    $config = Read-CursorJson (Join-Path $PSScriptRoot 'subscription.json')
    Assert-CursorIdentity $config (Get-CursorSubscription $config.packageBranch)
    $consumer = Get-CursorConsumer
    $plugin = Sync-CursorWorkspace $PSScriptRoot $config $consumer
    [Console]::Out.WriteLine((@{ pluginPaths = @($plugin) } | ConvertTo-Json -Compress))
} catch {
    [Console]::Error.WriteLine('[antennae-update] ' + $_.Exception.Message)
    # An update failure must not prevent Cursor from opening the user's project.
    # Never expose an unverified or half-installed plugin as a fallback.
    [Console]::Out.WriteLine('{"pluginPaths":[]}')
    exit 0
}
