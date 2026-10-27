$ErrorActionPreference = 'Continue'
$plink = 'C:\Program Files\PuTTY\plink.exe'

Write-Host '=== ports ==='
foreach ($p in 22, 80, 443, 8080, 7681) {
    $r = Test-NetConnection -ComputerName 192.168.66.1 -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue
    Write-Host ("  " + $p + " -> " + $r)
}

Write-Host '=== hostkey ==='
$out = & $plink -v -ssh -batch -pw admin root@192.168.66.1 'echo ok' 2>&1 | Out-String
$m = [regex]::Matches($out, 'SHA256:[A-Za-z0-9+/=]+')
if ($m.Count -gt 0) {
    Write-Host ("  KEY: " + $m[0].Value)
} else {
    Write-Host '  no fingerprint captured'
    ($out -split "`n" | Select-Object -First 12) | ForEach-Object { Write-Host ('  | ' + $_) }
}
