$ErrorActionPreference = 'Continue'
$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager'
$snap = Join-Path $root 'build\_snap8080\openwrt-luci-8080'
$man = Join-Path $root 'build\_snap8080_manifest.txt'
$lines = Get-Content $man
$idx = ($lines | Select-String -SimpleMatch '==FILES-MD5==').LineNumber
$files = $lines[$idx..($lines.Count - 1)] | Where-Object { $_ -match '^[0-9a-f]{32}  ' }

$junkRe = '^(theme-backup\d+-|imei-history\.log)|\.(bak|p8bak|kpbak|pre-myos)'
$copied = @(); $skipped = @()
foreach ($l in $files) {
    $rel = $l.Substring(34).Trim()
    if ($rel -match $junkRe) { $skipped += $rel; continue }
    $src = Join-Path $snap ($rel -replace '/', '\')
    if (-not (Test-Path -LiteralPath $src)) { Write-Host ('SNAP MISS: ' + $rel); continue }
    $dst = Join-Path $root ($rel -replace '/', '\')
    $need = $true
    if (Test-Path -LiteralPath $dst) {
        $sh = (Get-FileHash -LiteralPath $src -Algorithm MD5).Hash
        $dh = (Get-FileHash -LiteralPath $dst -Algorithm MD5).Hash
        if ($sh -eq $dh) { $need = $false }
    }
    if ($need) {
        $dir = Split-Path $dst -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
        Copy-Item -LiteralPath $src -Destination $dst -Force
        $copied += $rel
    }
}
Write-Host ('== 同步到仓库: ' + $copied.Count + ' 个 ==')
$copied | ForEach-Object { Write-Host ('  + ' + $_) }
Write-Host ('== 跳过备份/垃圾: ' + $skipped.Count + ' 个 ==')
$skipped | ForEach-Object { Write-Host ('  - ' + $_) }
