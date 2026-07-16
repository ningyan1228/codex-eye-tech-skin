[CmdletBinding()]
param(
  [int]$Port = 9336,
  [string]$ScreenshotPath
)

$ErrorActionPreference = 'Stop'
$node = (Get-Command node -ErrorAction Stop).Source
$arguments = @((Join-Path $PSScriptRoot 'injector.mjs'), '--verify', '--port', "$Port")
if ($ScreenshotPath) { $arguments += @('--screenshot', $ScreenshotPath) }
& $node @arguments
exit $LASTEXITCODE
