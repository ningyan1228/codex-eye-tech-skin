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
  $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  $powershell = (Get-Command powershell.exe).Source
  $trayScript = Join-Path $PSScriptRoot 'cyber-skin-tray.ps1'
  $shortcut = $shell.CreateShortcut((Join-Path $startMenu 'Codex Cyber Aurora.lnk'))
  $shortcut.TargetPath = $powershell
  $shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$trayScript`" -Port $Port -LaunchSkin"
  $shortcut.WorkingDirectory = $SkinRoot
  $shortcut.Description = 'Launch Codex Cyber Aurora and open its tray controls'
  $shortcut.Save()

  $desktop = [Environment]::GetFolderPath('Desktop')
  @('Codex Cyber Aurora.lnk', 'Codex Cyber Aurora - Change Background.lnk', 'Codex Cyber Aurora - Restore.lnk') |
    ForEach-Object { Remove-Item -LiteralPath (Join-Path $desktop $_) -Force -ErrorAction SilentlyContinue }
}

Write-Host 'Cyber Aurora installed. Search for Codex Cyber Aurora in the Start menu; controls will appear in the system tray.'
