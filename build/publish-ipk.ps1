<#
  一键构建并发布 8080 LuCI 实例 ipk
  ---------------------------------------------------------------
  流程：上传打包脚本 → 路由器上重新打包 → 拉回 PC → 校验 md5
        → 覆盖 GitHub Release「latest」的两个资产 → 更新 Release 说明

  用法（在仓库根目录）：
      powershell -ExecutionPolicy Bypass -File .\build\publish-ipk.ps1
      powershell -ExecutionPolicy Bypass -File .\build\publish-ipk.ps1 -Version 20261023-1
      powershell -ExecutionPolicy Bypass -File .\build\publish-ipk.ps1 -Router 192.168.66.1 -Password admin

  下载地址（永久不变）：
      https://github.com/h910056902/luci-theme-manger/releases/download/latest/nradio-luci-8080_all.ipk
#>
param(
    [string]$Version = ((Get-Date -Format "yyyyMMdd") + "-1"),
    [string]$Router = "192.168.66.1",
    [string]$UserName = "root",
    [string]$Password = $env:ROUTER_PW,
    [string]$Repo = "h910056902/luci-theme-manger",
    [string]$Tag = "latest",
    [string]$HostKey = "SHA256:66RpOE4kXKmaxFdKh4czcTQI5gME54QWVKjxu1/yNhs",
    [string]$Plink = "C:\Program Files\PuTTY\plink.exe",
    [string]$Pscp = "C:\Program Files\PuTTY\pscp.exe",
    [string]$Gh = "C:\tmp\bin\gh.exe"
)

$ErrorActionPreference = "Stop"
if (-not $Password) { throw "请先设置环境变量 ROUTER_PW（路由器 root 密码），不要把密码写进脚本" }
$repoRoot = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $repoRoot "build\out"
$pkg = "nradio-luci-8080"
$remote = "$UserName@$Router"
$stableName = "${pkg}_all.ipk"

function Invoke-Remote([string]$cmd) {
    $r = & $Plink -ssh -batch -hostkey $HostKey -pw $Password $remote $cmd 2>&1
    if ($LASTEXITCODE -ne 0) { throw "远端命令失败：$cmd`n$r" }
    return $r
}

Write-Host "[1/6] 上传打包脚本" -ForegroundColor Green
& $Pscp -scp -batch -hostkey $HostKey -pw $Password (Join-Path $PSScriptRoot "_build_ipk.sh") "${remote}:/tmp/_build_ipk.sh" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "上传 _build_ipk.sh 失败" }

Write-Host "[2/6] 路由器上打包 $pkg $Version" -ForegroundColor Green
$log = Invoke-Remote "sh /tmp/_build_ipk.sh $Version 2>&1"
$log | Select-Object -Last 8 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
$devMd5 = ($log | Select-String -Pattern '^MD5=(.+)$').Matches.Groups[1].Value
$devBytes = ($log | Select-String -Pattern '^BYTES=(\d+)$').Matches.Groups[1].Value
if (-not $devMd5) { throw "未取到打包结果（MD5/BYTES）" }

Write-Host "[3/6] 拉回 PC" -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$verName = "${pkg}_${Version}_all.ipk"
& $Pscp -scp -batch -hostkey $HostKey -pw $Password "${remote}:/tmp/$verName" "$outDir\" | Out-Null
if ($LASTEXITCODE -ne 0) { throw "下载 $verName 失败" }

$verPath = Join-Path $outDir $verName
if ((Get-Item $verPath).Length -ne [int]$devBytes) { throw "大小不一致，打包可能被截断" }

Write-Host "[4/6] 校验并生成固定名副本" -ForegroundColor Green
$localMd5 = (Get-FileHash $verPath -Algorithm MD5).Hash.ToLower()
if ($localMd5 -ne $devMd5) { throw "MD5 不一致：本地 $localMd5 / 设备 $devMd5" }
Write-Host "    MD5 $localMd5  ($devBytes 字节)" -ForegroundColor DarkGray

Copy-Item $verPath (Join-Path $outDir $stableName) -Force
$md5Path = Join-Path $outDir "$stableName.md5"
[System.IO.File]::WriteAllText($md5Path, ($localMd5 + "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "[5/6] 生成 Release 说明" -ForegroundColor Green
$notesPath = Join-Path $outDir "RELEASE_NOTES.md"
$notes = @"
# NRadio 8080 LuCI 实例包

滚动发布（rolling）：本 Release 的资产会被后续构建**原地替换**，下载地址保持不变。

## 固定下载地址

``````
https://github.com/$Repo/releases/download/$Tag/$stableName
``````

## 本次构建

- 版本：`$Version`
- 大小：`$devBytes` 字节
- MD5：``$localMd5``
- 架构：``all``（OpenWrt 21.02 / opkg）
- 构建时间：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## 安装

``````sh
opkg install /tmp/$stableName
# 或走应用商店本地安装（装完自动登记为已安装）
ubus call appcenter local '{"file":"/tmp/$stableName"}'
``````

卸载：

``````sh
opkg remove $pkg
``````

## 说明

- 包内容：8080 端口独立 LuCI 实例的私有覆盖层 —— 视图模板、``cgi-bin/luci`` 入口、
  ``mwrt-wifi`` / ``mwrt-svc`` 接口、bootstrap 主题定制、router3d / logo / fontawesome。
- 安装脚本按需重建 ``luci-static/*`` 符号链接，并幂等创建 ``uhttpd.openwrt8080``。
- 共享静态资源不重复打包，指向 ``/www/luci-static/*``。
"@
[System.IO.File]::WriteAllText($notesPath, $notes, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "[6/6] 上传到 Release $Tag" -ForegroundColor Green
& $Gh release upload $Tag (Join-Path $outDir $stableName) $md5Path --repo $Repo --clobber
if ($LASTEXITCODE -ne 0) { throw "上传资产失败" }
& $Gh release edit $Tag --repo $Repo --notes-file $notesPath | Out-Null
if ($LASTEXITCODE -ne 0) { throw "更新 Release 说明失败" }

Write-Host ""
Write-Host "完成：$Version / $localMd5" -ForegroundColor Cyan
Write-Host "下载：https://github.com/$Repo/releases/download/$Tag/$stableName" -ForegroundColor Cyan
