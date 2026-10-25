$ErrorActionPreference = 'Continue'
$repos = @(
    'kunpeng-router-ai-skills', 'nros-panel', 'openwrt-scripts',
    'kunpeng-istoreos', 'kunpeng-istoreos-style', 'myos-firmware-build',
    'nradio-plugin-installer', 'ssh-nradio-plugin-installer', 'istore'
)
foreach ($r in $repos) {
    $tmp = Join-Path $env:TEMP ("t_" + $r + ".json")
    curl.exe -s -m 30 "https://api.github.com/repos/h910056902/$r/git/trees/HEAD?recursive=1" -o $tmp 2>$null | Out-Null
    if (-not (Test-Path $tmp)) { continue }
    $j = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $j.tree) { continue }
    $hits = $j.tree | Where-Object { $_.path -match 'docker|kmod|veth' -and $_.type -eq 'blob' }
    if ($hits) {
        Write-Host ("== " + $r + " ==")
        foreach ($h in ($hits | Select-Object -First 12)) { Write-Host ("   " + $h.path + "  (" + $h.size + ")") }
    }
}
