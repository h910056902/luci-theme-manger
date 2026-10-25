$ErrorActionPreference = 'Continue'
$chrome = Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'
$profile = Join-Path $env:TEMP ('chrome-verify-' + (Get-Random))
$build = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build'

Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run',
    '--remote-debugging-port=9225', ('--user-data-dir=' + $profile), 'about:blank'
) -WindowStyle Hidden
Start-Sleep -Seconds 5

try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:9225/json/version' -TimeoutSec 5 -UseBasicParsing; Write-Host "CDP ready" } catch { Write-Host ("CDP failed: " + $_.Exception.Message) }

Push-Location $build
$env:CDP_PORT = '9225'
node .\_cdp_all.js
Pop-Location

Get-ChildItem $build\verify_*.png -ErrorAction SilentlyContinue | Select-Object Name, Length | Format-Table -AutoSize
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
