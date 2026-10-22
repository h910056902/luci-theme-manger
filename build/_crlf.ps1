$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\'
$files = @('usr\bin\kp8080-listen', 'etc\init.d\kp8080-listen', 'build\_deploy_listen.sh', 'build\_check_listen.sh', 'www\cgi-bin\luci')
foreach ($p in $files) {
    $f = $root + $p
    if (-not (Test-Path $f)) { Write-Host ($p + ' : MISSING'); continue }
    $b = [System.IO.File]::ReadAllBytes($f)
    $cr = 0
    foreach ($x in $b) { if ($x -eq 13) { $cr++ } }
    Write-Host ($p + ' : CR=' + $cr + ' bytes=' + $b.Length)
}
