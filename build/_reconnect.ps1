$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'
Write-Host ("PING: " + (Test-Connection -ComputerName $ip -Count 2 -Quiet))
foreach ($p in @(22, 80, 443, 8080, 7681)) {
    $ok = Test-NetConnection -ComputerName $ip -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue
    Write-Host ("PORT " + $p + ": " + $ok)
}
Write-Host "--- host key ---"
$out = & 'C:\Program Files\PuTTY\plink.exe' -v -ssh -batch -pw admin root@$ip 'echo ok' 2>&1
$out | Select-String -Pattern 'SHA256:' | Select-Object -First 3 | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) }
