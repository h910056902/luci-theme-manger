$ErrorActionPreference = 'Continue'
$chrome = Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe'
$profile = Join-Path $env:TEMP ('chrome-cdp-' + (Get-Random))
$build = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build'

Write-Host ("Chrome: " + $chrome)
Write-Host ("存在: " + (Test-Path $chrome))

Write-Host "== 启动 Chrome headless (CDP 9223) =="
Start-Process -FilePath $chrome -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--remote-debugging-port=9223', ('--user-data-dir=' + $profile), 'about:blank'
) -WindowStyle Hidden
Start-Sleep -Seconds 5

try {
    $v = Invoke-WebRequest -Uri 'http://127.0.0.1:9223/json/version' -TimeoutSec 5 -UseBasicParsing
    Write-Host ("  CDP 就绪: " + $v.Content.Replace("`n", ' ').Substring(0, [Math]::Min(160, $v.Content.Length)))
} catch {
    Write-Host ("  CDP 未就绪: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "== CDP 登录测试 =="
Push-Location $build
$env:CDP_PORT = '9223'
$env:SHOT_PREFIX = 'chrome_'
node .\_cdp_login2.js
Pop-Location

Write-Host ""
Get-ChildItem $build\chrome_*.png | Select-Object Name, Length | Format-Table -AutoSize

Write-Host "== 关闭 Chrome =="
Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Write-Host ("  剩余 chrome 进程: " + ((Get-Process chrome -ErrorAction SilentlyContinue | Measure-Object).Count))
