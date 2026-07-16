[CmdletBinding()]
param(
  [int]$Port = 9336,
  [string]$ScreenshotPath
)

$ErrorActionPreference = 'Stop'
function Get-NodeExecutable {
  $command = Get-Command node -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  $cacheRoot = Join-Path $HOME '.cache\codex-runtimes'
  $bundled = Get-ChildItem -Path (Join-Path $cacheRoot '*\dependencies\node\bin\node.exe') -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName
  if ($bundled) { return $bundled }
  throw 'Node.js was not found. Install Node.js or run this skin from a Codex installation that includes the bundled runtime.'
}

$node = Get-NodeExecutable
$arguments = @((Join-Path $PSScriptRoot 'injector.mjs'), '--verify', '--port', "$Port")
if ($ScreenshotPath) { $arguments += @('--screenshot', $ScreenshotPath) }
& $node @arguments
exit $LASTEXITCODE
