<#
  部署蜂窝页「视觉预览」到 NRadio 路由器（8080 实例）
  ---------------------------------------------------------------
  只上传一个静态 HTML 到 8080 实例的 www 根目录，不修改 LuCI 视图、
  不改 cgi-bin/luci，随时删除即可回退。

  用法（在本目录打开 PowerShell）：
      powershell -ExecutionPolicy Bypass -File .\deploy-preview.ps1
      powershell -ExecutionPolicy Bypass -File .\deploy-preview.ps1 -Router 192.168.66.1

  过程中会提示输入两次 root 密码：一次用于上传，一次用于落位。
#>
param(
    [string]$Router = "192.168.66.1",
    [string]$UserName = "root",
    [string]$Source = (Join-Path $PSScriptRoot "build\cellular-preview-device.html")
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $Source)) {
    Write-Host "找不到预览文件：$Source" -ForegroundColor Red
    Write-Host "请先确认 build\cellular-preview-device.html 存在。" -ForegroundColor Yellow
    exit 1
}

$size = (Get-Item $Source).Length
Write-Host ""
Write-Host "  目标设备 : ${UserName}@${Router}" -ForegroundColor Cyan
Write-Host "  待传文件 : $Source ($size 字节)" -ForegroundColor Cyan
Write-Host ""

# 路由器上已有同名文件时不覆盖，先备份
$backup = "/tmp/kpc-cellular-preview." + (Get-Date -Format "yyyyMMdd-HHmmss") + ".bak"

# ---- 1) 上传到 /tmp ----
Write-Host "[1/3] 上传到路由器 /tmp ..." -ForegroundColor Green
& scp -O -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL $Source "${UserName}@${Router}:/tmp/kpc-preview.html"
if ($LASTEXITCODE -ne 0) {
    Write-Host "上传失败（退出码 $LASTEXITCODE）。请检查密码、网络与路由器 SSH 状态。" -ForegroundColor Red
    exit 1
}

# ---- 2) 落位到 8080 实例的 www 根目录 ----
$remote = @'
set -e
DOC=""
for d in /overlay/nradio-apps/openwrt-luci-8080/www /www; do
  if [ -d "$d" ]; then DOC="$d"; break; fi
done
if [ -z "$DOC" ]; then echo "KP_ERR=no_docroot"; exit 2; fi
T="$DOC/kpc-cellular-preview.html"
if [ -f "$T" ]; then cp "$T" BACKUP_PLACEHOLDER 2>/dev/null || true; fi
cp /tmp/kpc-preview.html "$T"
chmod 644 "$T"
rm -f /tmp/kpc-preview.html
echo "KP_DOC=$DOC"
echo "KP_TARGET=$T"
ls -l "$T"
'@
$remote = $remote.Replace("BACKUP_PLACEHOLDER", $backup)

Write-Host "[2/3] 落位到 www 根目录 ..." -ForegroundColor Green
& ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL "${UserName}@${Router}" $remote
if ($LASTEXITCODE -ne 0) {
    Write-Host "落位失败（退出码 $LASTEXITCODE）。" -ForegroundColor Red
    exit 1
}

# ---- 3) 输出访问地址 ----
Write-Host ""
Write-Host "[3/3] 部署完成" -ForegroundColor Green
Write-Host ""
Write-Host "  电脑访问 : http://${Router}:8080/kpc-cellular-preview.html" -ForegroundColor Cyan
Write-Host "  手机访问 : 同一 WiFi 下打开上面的地址" -ForegroundColor Cyan
Write-Host ""
Write-Host "  回退方法 : ssh ${UserName}@${Router} 'rm -f /overlay/nradio-apps/openwrt-luci-8080/www/kpc-cellular-preview.html'" -ForegroundColor DarkGray
Write-Host "  备份位置 : $backup" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  注意：这是纯静态预览页，数据为模拟值，不连接任何后端接口；" -ForegroundColor Yellow
Write-Host "        线上蜂窝页 usr/lib/lua/luci/view/admin_status/nradio_cellular.htm 未被改动。" -ForegroundColor Yellow
