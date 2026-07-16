[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

function Show-LauncherMessage([string]$Text, [string]$Title, [System.Windows.Forms.MessageBoxIcon]$Icon) {
  [void][System.Windows.Forms.MessageBox]::Show($Text, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, $Icon)
}

$storeProcesses = @(Get-Process codex, ChatGPT -ErrorAction SilentlyContinue | Where-Object {
  $_.Path -like '*\WindowsApps\OpenAI.Codex_*'
})

if ($storeProcesses.Count -gt 0) {
  $prompt = @'
ChatGPT is still running. Cyber Aurora needs to close it before starting the wallpaper session.

Make sure there are no unsent messages or unsaved changes.

Choose Yes to close the current ChatGPT/Codex processes and start Cyber Aurora. Choose No to cancel.
'@
  $choice = [System.Windows.Forms.MessageBox]::Show(
    $prompt,
    'Cyber Aurora',
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning,
    [System.Windows.Forms.MessageBoxDefaultButton]::Button2
  )
  if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { exit 0 }

  $storeProcesses | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object {
    [void]$_.CloseMainWindow()
  }
  Start-Sleep -Seconds 2

  $remaining = @(Get-Process codex, ChatGPT -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -like '*\WindowsApps\OpenAI.Codex_*'
  })
  if ($remaining.Count -gt 0) { $remaining | Stop-Process -Force -ErrorAction Stop }
  Start-Sleep -Milliseconds 800
}

try {
  & (Join-Path $PSScriptRoot 'start-cyber-skin.ps1')
} catch {
  Show-LauncherMessage $_.Exception.Message 'Cyber Aurora failed to start' ([System.Windows.Forms.MessageBoxIcon]::Error)
  exit 1
}
