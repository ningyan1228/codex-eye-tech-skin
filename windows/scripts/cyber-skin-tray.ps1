[CmdletBinding()]
param(
  [int]$Port = 9336,
  [switch]$LaunchSkin
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$powershell = (Get-Command powershell.exe).Source

function Start-SkinScript([string]$Name, [string]$ExtraArguments = '') {
  $scriptPath = Join-Path $PSScriptRoot $Name
  $arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" $ExtraArguments"
  Start-Process -FilePath $powershell -ArgumentList $arguments -WindowStyle Hidden
}

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$launch = $menu.Items.Add('Apply / restart skin')
$background = $menu.Items.Add('Change background image...')
$restore = $menu.Items.Add('Restore default appearance')
$menu.Items.Add('-') | Out-Null
$exit = $menu.Items.Add('Exit tray manager')

$launch.add_Click({ Start-SkinScript 'start-cyber-skin.ps1' "-Port $Port -RestartExisting" })
$background.add_Click({ Start-SkinScript 'set-cyber-background.ps1' "-Port $Port" })
$restore.add_Click({ Start-SkinScript 'restore-cyber-skin.ps1' "-Port $Port" })

$tray = New-Object System.Windows.Forms.NotifyIcon
$tray.Icon = [System.Drawing.SystemIcons]::Information
$tray.Text = 'Codex Cyber Aurora'
$tray.ContextMenuStrip = $menu
$tray.Visible = $true
$tray.add_DoubleClick({ Start-SkinScript 'start-cyber-skin.ps1' "-Port $Port -RestartExisting" })
$exit.add_Click({ $tray.Visible = $false; $tray.Dispose(); [System.Windows.Forms.Application]::Exit() })

if ($LaunchSkin) { Start-SkinScript 'start-cyber-skin.ps1' "-Port $Port -RestartExisting" }
[System.Windows.Forms.Application]::Run()
