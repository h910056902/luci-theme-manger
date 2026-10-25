$ErrorActionPreference = 'Continue'
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$profile = Join-Path $env:TEMP ('edge-cdp-' + (Get-Random))
$build = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build'

Write-Host "== 启动 Edge headless (CDP 9222) =="
Start-Process -FilePath $edge -ArgumentList @(
    '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
    '--remote-debugging-port=9222', ('--user-data-dir=' + $profile), 'about:blank'
) -WindowStyle Hidden
Start-Sleep -Seconds 4

try {
    $v = Invoke-WebRequest -Uri 'http://127.0.0.1:9222/json/version' -TimeoutSec 5 -UseBasicParsing
    Write-Host ("  CDP 就绪: " + ($v.Content.Substring(0, [Math]::Min(120, $v.Content.Length))))
} catch {
    Write-Host ("  CDP 未就绪: " + $_.Exception.Message)
}

Write-Host ""
Write-Host "== 执行 CDP 登录脚本 =="
Push-Location $build
node .\_cdp_login.js
Pop-Location

Write-Host ""
Write-Host "== 截图文件 =="
Get-ChildItem $build\shot_*.png | Select-Object Name, Length | Format-Table -AutoSize

Write-Host "== 关闭 Edge =="
Get-Process msedge -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process -Name msedge -ErrorAction SilentlyContinue | Measure-Object | ForEach-Object { Write-Host ("  剩余 msedge 进程: " + $_.Count) }
