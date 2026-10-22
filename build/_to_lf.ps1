$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\'
$targets = @(
    'usr\bin\kp8080-listen',
    'etc\init.d\kp8080-listen'
)
foreach ($p in $targets) {
    $f = $root + $p
    if (-not (Test-Path $f)) { Write-Host ($p + ' MISSING'); continue }
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $out = New-Object System.Collections.Generic.List[byte]
    $n = 0
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 13) { $n++; continue }
        $out.Add($bytes[$i])
    }
    [System.IO.File]::WriteAllBytes($f, $out.ToArray())
    Write-Host ($p + ' : removed CR=' + $n + ' newBytes=' + $out.Count)
}
