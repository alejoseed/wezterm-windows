# install.ps1 — set up this WezTerm config on a Windows PC.
# Run from PowerShell:  .\install.ps1
#
# Does two things:
#   1. Copies .wezterm.lua into your Windows home (%USERPROFILE%).
#   2. Creates a Start Menu shortcut with a Ctrl+Alt+T global hotkey to launch WezTerm.

$ErrorActionPreference = 'Stop'

# --- 1. install the config -----------------------------------------------------
$src = Join-Path $PSScriptRoot '.wezterm.lua'
$dst = Join-Path $env:USERPROFILE '.wezterm.lua'
Copy-Item $src $dst -Force
Write-Host "config -> $dst"

# --- 2. create the launch shortcut + Ctrl+Alt+T hotkey -------------------------
# Resolve the WezTerm GUI launcher (PATH first, then a scoop install).
$target = (Get-Command wezterm-gui.exe -ErrorAction SilentlyContinue).Source
if (-not $target) { $target = Join-Path $env:USERPROFILE 'scoop\shims\wezterm-gui.exe' }
if (-not (Test-Path $target)) {
  Write-Warning "wezterm-gui.exe not found. Install WezTerm (e.g. 'scoop install wezterm'), then re-run."
  return
}

$ws  = New-Object -ComObject WScript.Shell
$lnk = Join-Path ([Environment]::GetFolderPath('Programs')) 'WezTerm.lnk'  # per-user Start Menu
$sc  = $ws.CreateShortcut($lnk)
$sc.TargetPath  = $target
$sc.Description = 'WezTerm'
$sc.Hotkey      = 'CTRL+ALT+T'
$sc.Save()
Write-Host "shortcut -> $lnk  (hotkey: Ctrl+Alt+T)"

Write-Host ""
Write-Host "Done. Launch with Ctrl+Alt+T (or search 'WezTerm' in the Start menu)."
Write-Host "Note: edit the 'wsl_distro' variable at the top of .wezterm.lua to match this PC ('wsl -l -q')."
