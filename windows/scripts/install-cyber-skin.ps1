[CmdletBinding()]
param(
  [switch]$RemoveLegacyShortcuts
)

$ErrorActionPreference = 'Stop'

if ($RemoveLegacyShortcuts) {
  $desktop = [Environment]::GetFolderPath('Desktop')
  $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  @('Codex Cyber Aurora.lnk', 'Codex Cyber Aurora - Change Background.lnk', 'Codex Cyber Aurora - Restore.lnk') |
    ForEach-Object { Remove-Item -LiteralPath (Join-Path $desktop $_) -Force -ErrorAction SilentlyContinue }
  Remove-Item -LiteralPath (Join-Path $startMenu 'Codex Cyber Aurora.lnk') -Force -ErrorAction SilentlyContinue
  Write-Host 'Legacy Cyber Aurora shortcuts were removed.'
}

Write-Host 'No installation is required. Cyber Aurora never writes Codex settings and never creates shortcuts.'
Write-Host 'Start it manually only after ChatGPT/Codex opens normally.'
