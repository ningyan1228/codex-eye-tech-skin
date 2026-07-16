[CmdletBinding()]
param(
  [int]$Port = 9336,
  [switch]$NoShortcuts
)

$ErrorActionPreference = 'Stop'
$SkinRoot = Split-Path -Parent $PSScriptRoot
$StateRoot = Join-Path $env:LOCALAPPDATA 'CodexCyberAurora'
$ConfigPath = Join-Path $HOME '.codex\config.toml'
$BackupPath = Join-Path $StateRoot 'config.before-cyber-skin.toml'
New-Item -ItemType Directory -Force -Path $StateRoot | Out-Null
if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Codex config not found: $ConfigPath" }
if (-not (Test-Path -LiteralPath $BackupPath)) { Copy-Item -LiteralPath $ConfigPath -Destination $BackupPath }

$content = Get-Content -LiteralPath $ConfigPath -Raw
$desktop = [regex]::Match($content, '(?ms)^\[desktop\]\s*\r?\n(?<body>.*?)(?=^\[|\z)')
if (-not $desktop.Success) {
  $content = $content.TrimEnd() + "`r`n`r`n[desktop]`r`n"
  $desktop = [regex]::Match($content, '(?ms)^\[desktop\]\s*\r?\n(?<body>.*?)(?=^\[|\z)')
}
$body = $desktop.Groups['body'].Value
$settings = [ordered]@{
  appearanceTheme = 'appearanceTheme = "dark"'
  appearanceDarkCodeThemeId = 'appearanceDarkCodeThemeId = "codex"'
  appearanceDarkChromeTheme = 'appearanceDarkChromeTheme = { accent = "#57E6DC", contrast = 76, fonts = { code = "Cascadia Code", ui = "Microsoft YaHei UI" }, ink = "#E6F5F5", opaqueWindows = true, semanticColors = { diffAdded = "#70D6A0", diffRemoved = "#F092A2", skill = "#9FB6FF" }, surface = "#07121F" }'
}
foreach ($key in $settings.Keys) {
  $pattern = "(?m)^$([regex]::Escape($key))\s*=.*$"
  if ([regex]::IsMatch($body, $pattern)) { $body = [regex]::Replace($body, $pattern, $settings[$key]) }
  else { $body = $body.TrimEnd() + "`r`n" + $settings[$key] + "`r`n" }
}
$content = $content.Substring(0, $desktop.Groups['body'].Index) + $body + $content.Substring($desktop.Groups['body'].Index + $desktop.Groups['body'].Length)
Set-Content -LiteralPath $ConfigPath -Value $content -Encoding utf8

if (-not $NoShortcuts) {
  $shell = New-Object -ComObject WScript.Shell
  $desktopPath = [Environment]::GetFolderPath('Desktop')
  $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  $powershell = (Get-Command powershell.exe).Source
  $shortcuts = @(
    @{ Name = 'Codex Cyber Aurora'; Script = 'start-cyber-skin.ps1'; Arguments = "-Port $Port -RestartExisting"; Folder = $desktopPath },
    @{ Name = 'Codex Cyber Aurora - Change Background'; Script = 'set-cyber-background.ps1'; Arguments = "-Port $Port"; Folder = $desktopPath },
    @{ Name = 'Codex Cyber Aurora - Restore'; Script = 'restore-cyber-skin.ps1'; Arguments = "-Port $Port"; Folder = $desktopPath },
    @{ Name = 'Codex Cyber Aurora'; Script = 'start-cyber-skin.ps1'; Arguments = "-Port $Port -RestartExisting"; Folder = $startMenu }
  )
  foreach ($item in $shortcuts) {
    $shortcut = $shell.CreateShortcut((Join-Path $item.Folder ($item.Name + '.lnk')))
    $shortcut.TargetPath = $powershell
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $PSScriptRoot $item.Script)`" $($item.Arguments)"
    $shortcut.WorkingDirectory = $SkinRoot
    $shortcut.Save()
  }
}

Write-Host 'Cyber Aurora installed. Launch it with the desktop shortcut or start-cyber-skin.ps1.'
