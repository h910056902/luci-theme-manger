<#
  把「在线设备真实读取」的三个文件部署到 8080 LuCI 实例。

  用法：
      powershell -ExecutionPolicy Bypass -File .\build\_deploy_clients.ps1

  流程：上传到 /tmp/kpc-deploy → 远端备份到 /tmp/kpc-deploy-<时间戳>
        → 落位 → lua 语法检查（失败自动回滚）→ 清 kp-status 缓存 → 打印标记
#>
param(
    [string]$Router = "192.168.66.1",
    [string]$UserName = "root",
    [string]$Password = "admin"
)

$ErrorActionPreference = "Stop"
$plink = "C:\Program Files\PuTTY\plink.exe"
$pscp = "C:\Program Files\PuTTY\pscp.exe"

$repo = Split-Path -Parent $PSScriptRoot
$stage = "/tmp/kpc-deploy"

$files = @(
    @{ local = "$repo\www\cgi-bin\luci"; remote = "luci"; mode = "755" },
    @{ local = "$repo\usr\lib\lua\luci\view\admin_status\index.htm"; remote = "index.htm"; mode = "644" },
    @{ local = "$repo\usr\lib\lua\luci\view\admin_status\nradio_details.htm"; remote = "nradio_details.htm"; mode = "644" }
)

foreach ($f in $files) {
    if (-not (Test-Path $f.local)) { throw "缺少本地文件: $($f.local)" }
}

$installer = @'
set -e
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
S=/tmp/kpc-deploy
[ -d "$D" ] || { echo "KP_ERR=no_instance_root"; exit 2; }
[ -d "$V" ] || { echo "KP_ERR=no_view_dir"; exit 2; }

TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-deploy-$TS
mkdir -p "$BAK"
cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null || true
cp "$V/index.htm" "$BAK/index.htm" 2>/dev/null || true
cp "$V/nradio_details.htm" "$BAK/nradio_details.htm" 2>/dev/null || true

cp "$S/luci" "$D/www/cgi-bin/luci"
cp "$S/index.htm" "$V/index.htm"
cp "$S/nradio_details.htm" "$V/nradio_details.htm"
chmod 755 "$D/www/cgi-bin/luci"
chmod 644 "$V/index.htm" "$V/nradio_details.htm"

if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
  cp "$BAK/luci" "$D/www/cgi-bin/luci"
  cp "$BAK/index.htm" "$V/index.htm"
  cp "$BAK/nradio_details.htm" "$V/nradio_details.htm"
  echo "SYNTAX_FAIL"
  cat /tmp/kpc-syntax.err
  exit 1
fi
echo "SYNTAX_OK"

rm -f /tmp/kp-status.json
echo "MARK_cgi=$(grep -c 'kp_online_devices' "$D/www/cgi-bin/luci")"
echo "MARK_details=$(grep -c 'online_clients' "$V/nradio_details.htm")"
echo "MARK_index=$(grep -c 'd.clients' "$V/index.htm")"
ls -l "$D/www/cgi-bin/luci" "$V/index.htm" "$V/nradio_details.htm"
echo "BAK=$BAK"
'@

$tmp = Join-Path $env:TEMP "kpc-install.sh"
[System.IO.File]::WriteAllText($tmp, ($installer -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "[1/4] 建立主机信任 ..." -ForegroundColor Green
$probe = & cmd /c "echo y| `"$plink`" -ssh -pw $Password $UserName@$Router `"echo KP_READY`" 2>&1"
if (-not ($probe -match "KP_READY")) {
    Write-Host ($probe -join "`n") -ForegroundColor Red
    throw "无法登录 $UserName@$Router"
}

Write-Host "[2/4] 上传到 $stage ..." -ForegroundColor Green
& $plink -ssh -batch -pw $Password "$UserName@$Router" "mkdir -p $stage"
if ($LASTEXITCODE -ne 0) { throw "远端建目录失败" }
foreach ($f in $files) {
    & $pscp -batch -pw $Password $f.local "${UserName}@${Router}:$stage/$($f.remote)"
    if ($LASTEXITCODE -ne 0) { throw "上传失败: $($f.remote)" }
}
& $pscp -batch -pw $Password $tmp "${UserName}@${Router}:$stage/install.sh"
if ($LASTEXITCODE -ne 0) { throw "上传 install.sh 失败" }

Write-Host "[3/4] 落位并校验 ..." -ForegroundColor Green
& $plink -ssh -batch -pw $Password "$UserName@$Router" "sh $stage/install.sh 2>&1"
$rc = $LASTEXITCODE

Write-Host "[4/4] 清理暂存 ..." -ForegroundColor Green
& $plink -ssh -batch -pw $Password "$UserName@$Router" "rm -rf $stage" | Out-Null

if ($rc -ne 0) { Write-Host "部署失败（rc=$rc），远端已回滚" -ForegroundColor Red; exit $rc }
Write-Host "部署完成：http://${Router}:8080/cgi-bin/luci/admin/status/details" -ForegroundColor Cyan
