$ErrorActionPreference = 'Continue'
$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager'
$ipk  = Join-Path $env:USERPROFILE 'Desktop\kp-restore-20261025-194209_all.ipk'
$work = Join-Path $root 'build\_ocpayload'
$data = Join-Path $work 'data'
$out  = Join-Path $root 'build\openclash_payload.tar.gz'

if (-not (Test-Path $ipk)) { Write-Host "IPK NOT FOUND: $ipk"; exit 1 }
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $work | Out-Null
New-Item -ItemType Directory -Force $data | Out-Null

Write-Host "== unpack ipk =="
tar -xzf $ipk -C $work
tar -xzf (Join-Path $work 'data.tar.gz') -C $data

$paths = @(
    'etc/openclash',
    'etc/config/openclash',
    'etc/init.d/openclash',
    'usr/share/openclash',
    'usr/lib/lua/luci/controller/openclash.lua',
    'usr/lib/lua/luci/view/openclash',
    'usr/lib/lua/luci/model/cbi/openclash',
    'www/luci-static/resources/openclash'
)

$exist = @()
foreach ($p in $paths) {
    $full = Join-Path $data $p
    if (Test-Path $full) { $exist += $p; Write-Host ("  OK   " + $p) }
    else { Write-Host ("  MISS " + $p) }
}

Write-Host "== pack payload =="
Push-Location $data
Remove-Item $out -Force -ErrorAction SilentlyContinue
tar -czf $out @exist
Pop-Location

if (Test-Path $out) {
    Write-Host ("payload: " + $out + "  " + (Get-Item $out).Length + " bytes")
} else {
    Write-Host "pack FAILED"
}
