[CmdletBinding()]
param(
  [int]$Port = 9336,
  [switch]$RestartExisting,
  [switch]$ForegroundInjector
)

$ErrorActionPreference = 'Stop'
$SkinRoot = Split-Path -Parent $PSScriptRoot
$Injector = Join-Path $PSScriptRoot 'injector.mjs'
$StateRoot = Join-Path $env:LOCALAPPDATA 'CodexCyberAurora'
$StatePath = Join-Path $StateRoot 'state.json'
New-Item -ItemType Directory -Force -Path $StateRoot | Out-Null

function Test-CodexDebugPort([int]$CandidatePort) {
  try {
    $targets = Invoke-RestMethod "http://127.0.0.1:$CandidatePort/json/list" -TimeoutSec 1
    return [bool]($targets | Where-Object { $_.type -eq 'page' -and $_.url -like 'app://*' })
  } catch { return $false }
}

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
$debugReady = Test-CodexDebugPort $Port
$processes = @(Get-Process codex, ChatGPT -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })
if (-not $debugReady -and $processes.Count -gt 0) {
  if (-not $RestartExisting) { throw "Codex is already running without skin debugging. Close it or rerun with -RestartExisting." }
  foreach ($process in $processes) { [void]$process.CloseMainWindow() }
  Start-Sleep -Seconds 2
  Get-Process codex, ChatGPT -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Milliseconds 700
}

if (-not (Test-CodexDebugPort $Port)) {
  $package = Get-AppxPackage OpenAI.Codex | Sort-Object Version -Descending | Select-Object -First 1
  if (-not $package) { throw 'The OpenAI.Codex Store package is not installed.' }
  $candidates = @(
    (Join-Path $package.InstallLocation 'app\resources\codex.exe'),
    (Join-Path $package.InstallLocation 'app\ChatGPT.exe'),
    (Join-Path $package.InstallLocation 'app\resources\ChatGPT.exe')
  )
  $exe = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if (-not $exe) { throw 'Could not locate the current Codex executable in its Store package.' }
  Start-Process -FilePath $exe -ArgumentList "--remote-debugging-port=$Port"
}

$deadline = (Get-Date).AddSeconds(30)
while (-not (Test-CodexDebugPort $Port)) {
  if ((Get-Date) -ge $deadline) { throw "Codex did not expose the local debugging port $Port within 30 seconds." }
  Start-Sleep -Milliseconds 400
}

if (Test-Path -LiteralPath $StatePath) {
  try { $old = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json; if ($old.injectorPid) { Stop-Process -Id ([int]$old.injectorPid) -Force -ErrorAction SilentlyContinue } } catch {}
}
if ($ForegroundInjector) { & $node $Injector --watch --port $Port; exit $LASTEXITCODE }

$stdout = Join-Path $StateRoot 'injector.log'
$stderr = Join-Path $StateRoot 'injector-error.log'
$daemon = Start-Process -FilePath $node -ArgumentList @("`"$Injector`"", '--watch', '--port', "$Port") -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
@{ port = $Port; injectorPid = $daemon.Id; startedAt = (Get-Date).ToString('o'); skinRoot = $SkinRoot } | ConvertTo-Json | Set-Content -LiteralPath $StatePath -Encoding utf8

for ($attempt = 0; $attempt -lt 45; $attempt++) {
  Start-Sleep -Milliseconds 700
  & $node $Injector --verify --port $Port *> $null
  if ($LASTEXITCODE -eq 0) { Write-Host "Cyber Aurora is active on port $Port."; exit 0 }
}
throw 'Cyber Aurora launched but verification failed. See the injector logs in %LOCALAPPDATA%\CodexCyberAurora.'
