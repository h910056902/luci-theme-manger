$ErrorActionPreference = 'Continue'
$chrome = Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'
$profile = Join-Path $env:TEMP ('chrome-sw-' + (Get-Random))
$build = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build'

Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run',
    '--remote-debugging-port=9228', ('--user-data-dir=' + $profile), 'about:blank'
) -WindowStyle Hidden
Start-Sleep -Seconds 5

Push-Location $build
$env:CDP_PORT = '9228'
node .\_cdp_sweep.js
Pop-Location

Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
