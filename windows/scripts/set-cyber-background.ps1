[CmdletBinding()]
param(
  [string]$Path,
  [int]$Port = 9336
)

$ErrorActionPreference = 'Stop'
$SkinRoot = Split-Path -Parent $PSScriptRoot
$Assets = Join-Path $SkinRoot 'assets'
$Backgrounds = Join-Path $Assets 'backgrounds'
$Config = Join-Path $Assets 'background.json'

if (-not $Path) {
  Add-Type -AssemblyName System.Windows.Forms
  $dialog = New-Object System.Windows.Forms.OpenFileDialog
  $dialog.Title = 'Select a Codex Cyber Aurora background image'
  $dialog.Filter = 'Image files|*.png;*.jpg;*.jpeg;*.webp|All files|*.*'
  if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { Write-Host 'No background was selected.'; exit 0 }
  $Path = $dialog.FileName
}

$source = Get-Item -LiteralPath $Path -ErrorAction Stop
if ($source.Length -gt 15MB) { throw 'Background image must be 15 MB or smaller.' }
$extension = $source.Extension.ToLowerInvariant()
if ($extension -notin @('.png', '.jpg', '.jpeg', '.webp')) { throw 'Choose a PNG, JPG, JPEG, or WebP image.' }

New-Item -ItemType Directory -Force -Path $Backgrounds | Out-Null
$targetName = "custom-$((Get-Date).ToString('yyyyMMdd-HHmmss'))$extension"
$target = Join-Path $Backgrounds $targetName
Copy-Item -LiteralPath $source.FullName -Destination $target
@{ file = "backgrounds/$targetName"; label = [System.IO.Path]::GetFileNameWithoutExtension($source.Name) } | ConvertTo-Json | Set-Content -LiteralPath $Config -Encoding utf8

$node = Get-Command node -ErrorAction Stop
$debugReady = $false
try {
  $targets = Invoke-RestMethod "http://127.0.0.1:$Port/json/list" -TimeoutSec 1
  $debugReady = [bool]($targets | Where-Object { $_.type -eq 'page' -and $_.url -like 'app://*' })
} catch {}
if ($debugReady) {
  & $node.Source (Join-Path $PSScriptRoot 'injector.mjs') --once --port $Port
  if ($LASTEXITCODE -ne 0) { throw 'The selected background was saved but could not be applied to the current Codex window.' }
  Write-Host 'Background updated in the running Cyber Aurora skin.'
  exit 0
}
Write-Host 'Background saved. Start Codex Cyber Aurora to apply it.'
