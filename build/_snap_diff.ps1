$ErrorActionPreference = 'Continue'
$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager'
$man = Join-Path $root 'build\_snap8080_manifest.txt'
$lines = Get-Content $man
$idx = ($lines | Select-String -SimpleMatch '==FILES-MD5==').LineNumber
$files = $lines[$idx..($lines.Count - 1)] | Where-Object { $_ -match '^[0-9a-f]{32}  ' }

$same = @(); $diff = @(); $miss = @()
foreach ($l in $files) {
    $h = $l.Substring(0, 32)
    $rel = $l.Substring(34).Trim()
    $local = Join-Path $root ($rel -replace '/', '\')
    if (-not (Test-Path -LiteralPath $local)) { $miss += $rel; continue }
    $lh = (Get-FileHash -LiteralPath $local -Algorithm MD5).Hash.ToLower()
    if ($lh -eq $h) { $same += $rel } else { $diff += $rel }
}

$junk = '\\(theme-backup|.*\.bak|.*\.p8bak)'
$missReal = $miss | Where-Object { $_ -notmatch $junk }
$diffReal = $diff | Where-Object { $_ -notmatch $junk }

$report = @()
$report += '=== 8080 实例快照比对（设备 md5 vs 仓库工作区）==='
$report += ('设备文件总数: ' + $files.Count + ' | 相同: ' + $same.Count + ' | 不同: ' + $diff.Count + ' | 仓库缺失: ' + $miss.Count)
$report += ''
$report += '--- [A] 内容不同（仓库落后于设备）' + ' (' + $diffReal.Count + ') ---'
$report += ($diffReal | Sort-Object)
$report += ''
$report += '--- [B] 设备有、仓库无（需入库）' + ' (' + $missReal.Count + ') ---'
$report += ($missReal | Sort-Object)
$report += ''
$report += '--- [C] 已识别为备份/垃圾（不同或缺失但不入库） ---'
$report += (($diff + $miss) | Where-Object { $_ -match $junk } | Sort-Object)
$report | Out-File -Encoding utf8 (Join-Path $root 'build\_snap8080_diff.txt')
$report | Select-Object -First 200
