$ErrorActionPreference = 'Continue'
$repos = @(
    'luci-theme-manger', 'nros-panel', 'istore', 'kunpeng-istoreos',
    'kunpeng-router-ai-skills', 'openwrt-scripts', 'kunpeng-istoreos-style',
    'myos-firmware-build', 'nradio-plugin-installer', 'ssh-nradio-plugin-installer'
)

$out = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\_oc_hits.txt'
Remove-Item $out -Force -ErrorAction SilentlyContinue

foreach ($r in $repos) {
    $url = "https://api.github.com/repos/h910056902/$r/git/trees/HEAD?recursive=1"
    $tmp = Join-Path $env:TEMP ("tree_" + $r + ".json")
    curl.exe -s -m 30 $url -o $tmp 2>$null | Out-Null
    if (-not (Test-Path $tmp)) { continue }
    $j = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $j.tree) { Write-Host ("  " + $r + ": no tree"); continue }
    $hits = $j.tree | Where-Object { $_.path -match 'ocspeed' }
    if ($hits) {
        Write-Host ("== " + $r + " ==")
        foreach ($h in $hits) {
            Write-Host ("   " + $h.path + "  (" + $h.type + ", " + $h.size + ")")
            Add-Content -Path $out -Value ($r + "|" + $h.path + "|" + $h.type)
        }
    }
}
if (Test-Path $out) { Write-Host "`nSTOP: hits saved" } else { Write-Host "`nno hits in any repo" }
