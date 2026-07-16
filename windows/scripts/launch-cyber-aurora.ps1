[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

function Show-LauncherMessage([string]$Text, [string]$Title, [System.Windows.Forms.MessageBoxIcon]$Icon) {
  [void][System.Windows.Forms.MessageBox]::Show($Text, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, $Icon)
}

$openWindows = @(Get-Process codex, ChatGPT -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })
if ($openWindows.Count -gt 0) {
  Show-LauncherMessage '请先自行关闭所有 ChatGPT / Codex 窗口，再点击任务栏里的 Cyber Aurora 图标。启动器不会强制关闭任何窗口。' 'Cyber Aurora' ([System.Windows.Forms.MessageBoxIcon]::Information)
  exit 1
}

try {
  & (Join-Path $PSScriptRoot 'start-cyber-skin.ps1')
} catch {
  Show-LauncherMessage $_.Exception.Message 'Cyber Aurora 未启动' ([System.Windows.Forms.MessageBoxIcon]::Error)
  exit 1
}
