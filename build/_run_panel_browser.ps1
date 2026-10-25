$ErrorActionPreference = 'Continue'
$chrome = Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'
$profile = Join-Path $env:TEMP ('chrome-panel-' + (Get-Random))
$build = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build'

Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run',
    '--remote-debugging-port=9224', ('--user-data-dir=' + $profile), 'about:blank'
) -WindowStyle Hidden
Start-Sleep -Seconds 5

try { $null = Invoke-WebRequest -Uri 'http://127.0.0.1:9224/json/version' -TimeoutSec 5 -UseBasicParsing; Write-Host "  CDP 就绪" } catch { Write-Host ("  CDP 失败: " + $_.Exception.Message) }

Push-Location $build
$env:CDP_PORT = '9224'
$env:SHOT_PREFIX = 'panel_'
$env:TARGET_URL = 'http://192.168.66.1:8080/'
node .\_cdp_panel.js
Pop-Location

Get-ChildItem $build\panel_*.png -ErrorAction SilentlyContinue | Select-Object Name, Length | Format-Table -AutoSize
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
