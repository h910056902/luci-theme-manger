$ErrorActionPreference = 'Continue'
$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager'
$manifest = Get-Content (Join-Path $root 'build\device_manifest.txt') -Encoding UTF8

$dev = @{}
foreach ($line in $manifest) {
    if ($line -match '^(\d+) \./(.+)$') { $dev[$matches[2]] = [int]$matches[1] }
}
Write-Host ("device files: " + $dev.Count)

$tracked = & git -C $root ls-files 'www/*' 'usr/*' 'etc/*' 'lib/*' 2>$null
$missing = @()
$differ = @()
$same = 0
foreach ($rel in $tracked) {
    $rel = $rel -replace '\\', '/'
    if ($rel -notmatch '^(www|usr|etc|lib)/') { continue }
    $local = Join-Path $root $rel
    if (-not (Test-Path $local)) { continue }
    $size = (Get-Item $local).Length
    if (-not $dev.ContainsKey($rel)) {
        $missing += ("{0}  repo={1}" -f $rel, $size)
    } elseif ($dev[$rel] -ne $size) {
        $differ += ("{0}  repo={1}  dev={2}" -f $rel, $size, $dev[$rel])
    } else {
        $same++
    }
}

Write-Host ("match: " + $same)
Write-Host ""
Write-Host "== MISSING ON DEVICE =="
if ($missing.Count -eq 0) { Write-Host "  none" } else { $missing | ForEach-Object { Write-Host ("  " + $_) } }
Write-Host ""
Write-Host "== SIZE DIFF =="
if ($differ.Count -eq 0) { Write-Host "  none" } else { $differ | ForEach-Object { Write-Host ("  " + $_) } }

Write-Host ""
Write-Host "== EXTRA ON DEVICE =="
$extra = @($dev.Keys | Where-Object { $tracked -notcontains $_ } | Sort-Object)
$extra | Select-Object -First 15 | ForEach-Object { Write-Host ("  " + $_ + "  " + $dev[$_] ) }
Write-Host ("  total extra: " + $extra.Count)
