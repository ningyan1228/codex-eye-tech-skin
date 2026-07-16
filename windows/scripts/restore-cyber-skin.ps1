[CmdletBinding()]
param(
  [int]$Port = 9336,
  [switch]$Uninstall,
  [switch]$RestoreBaseTheme
)

$ErrorActionPreference = 'Stop'
$StateRoot = Join-Path $env:LOCALAPPDATA 'CodexCyberAurora'
$StatePath = Join-Path $StateRoot 'state.json'
if (Test-Path -LiteralPath $StatePath) {
  try { $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json; if ($state.injectorPid) { Stop-Process -Id ([int]$state.injectorPid) -Force -ErrorAction SilentlyContinue } } catch {}
  Remove-Item -LiteralPath $StatePath -Force -ErrorAction SilentlyContinue
}

$node = Get-Command node -ErrorAction Stop
try { & $node.Source (Join-Path $PSScriptRoot 'injector.mjs') --remove --port $Port --timeout-ms 3000 } catch {}

if ($Uninstall) {
  $desktop = [Environment]::GetFolderPath('Desktop')
  $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  @('Codex Cyber Aurora.lnk', 'Codex Cyber Aurora - Change Background.lnk', 'Codex Cyber Aurora - Restore.lnk') | ForEach-Object { Remove-Item -LiteralPath (Join-Path $desktop $_) -Force -ErrorAction SilentlyContinue }
  Remove-Item -LiteralPath (Join-Path $startMenu 'Codex Cyber Aurora.lnk') -Force -ErrorAction SilentlyContinue
}

if ($RestoreBaseTheme) {
  $backup = Join-Path $StateRoot 'config.before-cyber-skin.toml'
  $config = Join-Path $HOME '.codex\config.toml'
  if (-not (Test-Path -LiteralPath $backup)) { throw 'No pre-install config backup is available.' }
  $backupContent = Get-Content -LiteralPath $backup -Raw
  $currentContent = Get-Content -LiteralPath $config -Raw
  foreach ($key in @('appearanceTheme', 'appearanceDarkCodeThemeId', 'appearanceDarkChromeTheme')) {
    $pattern = "(?m)^$([regex]::Escape($key))\s*=.*(?:\r?\n)?"
    $saved = [regex]::Match($backupContent, $pattern)
    if ([regex]::IsMatch($currentContent, $pattern)) {
      $replacement = if ($saved.Success) { $saved.Value.TrimEnd("`r", "`n") + "`r`n" } else { '' }
      $currentContent = [regex]::Replace($currentContent, $pattern, $replacement, 1)
      continue
    }
    if (-not $saved.Success) { continue }
    $desktop = [regex]::Match($currentContent, '(?ms)^\[desktop\]\s*\r?\n(?<body>.*?)(?=^\[|\z)')
    if (-not $desktop.Success) {
      $currentContent = $currentContent.TrimEnd() + "`r`n`r`n[desktop]`r`n"
      $desktop = [regex]::Match($currentContent, '(?ms)^\[desktop\]\s*\r?\n(?<body>.*?)(?=^\[|\z)')
    }
    $body = $desktop.Groups['body'].Value.TrimEnd() + "`r`n" + $saved.Value.TrimEnd("`r", "`n") + "`r`n"
    $currentContent = $currentContent.Substring(0, $desktop.Groups['body'].Index) + $body + $currentContent.Substring($desktop.Groups['body'].Index + $desktop.Groups['body'].Length)
  }
  Set-Content -LiteralPath $config -Value $currentContent -Encoding utf8
}
Write-Host 'Cyber Aurora was removed from the current Codex window.'
