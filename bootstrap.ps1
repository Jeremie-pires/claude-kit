<#
.SYNOPSIS
  Sync this machine's ~/.claude with the claude-kit repo. Idempotent.

.DESCRIPTION
  Default = PREVIEW (nothing written, shows the diff). Use -Apply to write.
  First run on a new PC:
    gh repo clone Jeremie-pires/claude-kit $HOME\.claude-kit
    & $HOME\.claude-kit\bootstrap.ps1            # preview
    & $HOME\.claude-kit\bootstrap.ps1 -Apply     # apply
  After that, a SessionStart hook runs it with -Apply -Quiet on every Claude launch.

  What it touches: ~/.claude/settings.json (merged, backed up), ~/.claude/CLAUDE.md,
  ~/.claude/statusline-command.sh. It never touches credentials, history or projects.
#>
[CmdletBinding()]
param(
  [switch]$Apply,
  [switch]$Quiet,
  [string]$KitDir = (Join-Path $HOME '.claude-kit'),
  [string]$Repo = 'https://github.com/Jeremie-pires/claude-kit.git'
)

$ErrorActionPreference = 'Continue'
$claude = Join-Path $HOME '.claude'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Say($m) { if (-not $Quiet) { Write-Host $m } }
function HasProp($o, $n) { return $null -ne $o.PSObject.Properties[$n] }
function SetProp($o, $n, $v) {
  if (HasProp $o $n) { $o.$n = $v } else { $o | Add-Member -NotePropertyName $n -NotePropertyValue $v }
}
function ReadJson($p) {
  if (Test-Path $p) {
    $t = [IO.File]::ReadAllText($p, $utf8)
    if ($t.Trim()) { return ($t | ConvertFrom-Json) }
  }
  return [pscustomobject]@{}
}
function ToJson($o) {
  $j = $o | ConvertTo-Json -Depth 20
  return ($j -replace '\\u0027', "'" -replace '\\u003c', '<' -replace '\\u003e', '>' -replace '\\u0026', '&')
}
function Sync-File($src, $dst) {
  if (-not (Test-Path $src)) { return }
  $same = (Test-Path $dst) -and ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash)
  if ($same) { Say "= $dst (unchanged)"; return }
  if (-not $Apply) { Say "~ would update $dst"; return }
  if (Test-Path $dst) { Copy-Item $dst "$dst.bak-$stamp" -Force }
  Copy-Item $src $dst -Force
  Say "+ updated $dst"
}

# 1. Get / update the kit (fast-forward only; offline is fine)
if (Test-Path (Join-Path $KitDir '.git')) {
  $null = & git -C $KitDir pull --ff-only --quiet 2>&1
  if ($LASTEXITCODE -ne 0) { Say '! git pull skipped (offline or local changes); using local kit' }
} else {
  if (-not $Apply) { Say "Kit not found at $KitDir. Clone it first: gh repo clone Jeremie-pires/claude-kit $KitDir"; exit 1 }
  $null = & git clone --quiet $Repo $KitDir 2>&1
  if ($LASTEXITCODE -ne 0) { Say '! clone failed (auth? network?)'; exit 1 }
}

if (-not (Test-Path $claude)) { New-Item -ItemType Directory -Force $claude | Out-Null }

# 2. Merge settings.json (kit keys only; everything local is preserved)
$basePath = Join-Path $KitDir 'global\settings.base.json'
$curPath = Join-Path $claude 'settings.json'
$base = ReadJson $basePath
$cur = ReadJson $curPath
$before = ToJson (ReadJson $curPath)

# statusLine: kit wins (portable path)
if (HasProp $base 'statusLine') { SetProp $cur 'statusLine' $base.statusLine }

# maps: add/overwrite kit entries, keep the rest
foreach ($k in 'env', 'extraKnownMarketplaces', 'enabledPlugins') {
  if (HasProp $base $k) {
    if (-not (HasProp $cur $k)) { SetProp $cur $k ([pscustomobject]@{}) }
    foreach ($p in $base.$k.PSObject.Properties) { SetProp $cur.$k $p.Name $p.Value }
  }
}

# permissions: union of lists
if (HasProp $base 'permissions') {
  if (-not (HasProp $cur 'permissions')) { SetProp $cur 'permissions' ([pscustomobject]@{}) }
  foreach ($list in 'allow', 'ask', 'deny') {
    if (HasProp $base.permissions $list) {
      $existing = @()
      if (HasProp $cur.permissions $list) { $existing = @($cur.permissions.$list) }
      $merged = @($existing + @($base.permissions.$list) | Select-Object -Unique)
      SetProp $cur.permissions $list $merged
    }
  }
}

# hooks: append kit entries whose command is not already present
if (HasProp $base 'hooks') {
  if (-not (HasProp $cur 'hooks')) { SetProp $cur 'hooks' ([pscustomobject]@{}) }
  foreach ($ev in $base.hooks.PSObject.Properties) {
    $curList = @()
    if (HasProp $cur.hooks $ev.Name) { $curList = @($cur.hooks.($ev.Name)) }
    $cmds = @($curList | ForEach-Object { $_.hooks } | ForEach-Object { $_.command })
    foreach ($entry in @($ev.Value)) {
      $new = @($entry.hooks | Where-Object { $cmds -notcontains $_.command })
      if ($new.Count -gt 0) { $curList += $entry }
    }
    SetProp $cur.hooks $ev.Name $curList
  }
}

# defaults: only when missing locally
foreach ($k in 'autoUpdatesChannel', 'theme', 'model') {
  if ((HasProp $base $k) -and -not (HasProp $cur $k)) { SetProp $cur $k $base.$k }
}

$after = ToJson $cur
if ($before -eq $after) {
  Say '= settings.json (unchanged)'
} elseif (-not $Apply) {
  $a = Join-Path $env:TEMP 'claude-settings.current.json'
  $b = Join-Path $env:TEMP 'claude-settings.merged.json'
  [IO.File]::WriteAllText($a, $before, $utf8)
  [IO.File]::WriteAllText($b, $after, $utf8)
  Say '~ settings.json would change:'
  & git --no-pager diff --no-index --no-color -U1 -- $a $b
} else {
  if (Test-Path $curPath) { Copy-Item $curPath "$curPath.bak-$stamp" -Force }
  [IO.File]::WriteAllText($curPath, $after, $utf8)
  Say '+ settings.json updated (backup kept)'
  Get-ChildItem $claude -Filter 'settings.json.bak-*' | Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 5 | Remove-Item -Force
}

# 3. Global rules and statusline script
Sync-File (Join-Path $KitDir 'global\CLAUDE.md') (Join-Path $claude 'CLAUDE.md')
Sync-File (Join-Path $KitDir 'global\statusline-command.sh') (Join-Path $claude 'statusline-command.sh')

# 4. Install enabled kit plugins that are not installed yet (enabledPlugins alone does not download them)
$installedPath = Join-Path $claude 'plugins\installed_plugins.json'
$installed = @()
if (Test-Path $installedPath) { $installed = @((ReadJson $installedPath).plugins.PSObject.Properties.Name) }
$wanted = @()
if (HasProp $base 'enabledPlugins') { $wanted = @($base.enabledPlugins.PSObject.Properties | Where-Object { $_.Value } | ForEach-Object { $_.Name }) }
$missing = @($wanted | Where-Object { $installed -notcontains $_ })
$claudeCli = Get-Command claude -ErrorAction SilentlyContinue

foreach ($id in $missing) {
  if (-not $Apply) { Say "~ would install plugin $id"; continue }
  if (-not $claudeCli) { Say "! claude CLI not found; run in Claude Code: /plugin install $id"; continue }
  if ($Quiet) {
    # SessionStart hook: never block startup, install in the background
    Start-Process -FilePath $claudeCli.Source -ArgumentList @('plugin', 'install', $id, '--scope', 'user') -WindowStyle Hidden
  } else {
    Say "+ installing plugin $id"
    & $claudeCli.Source plugin install $id --scope user
    if ($LASTEXITCODE -ne 0) { Say "! install failed for $id; run in Claude Code: /plugin install $id" }
  }
}

if (-not $Apply) { Say "`nPreview only. Re-run with -Apply to write." }
