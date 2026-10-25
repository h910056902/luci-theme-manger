$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'

$p = Test-Connection -ComputerName $ip -Count 3 -Quiet
Write-Host ("PING: " + $p)

foreach ($port in 22, 80, 8080, 7681) {
    $c = New-Object Net.Sockets.TcpClient
    $ok = $false
    try {
        $ar = $c.BeginConnect($ip, $port, $null, $null)
        $ok = $ar.AsyncWaitHandle.WaitOne(2000)
        if ($ok) { $c.EndConnect($ar); Write-Host ("PORT " + $port + ": OPEN") }
        else { Write-Host ("PORT " + $port + ": TIMEOUT") }
    } catch {
        Write-Host ("PORT " + $port + ": REFUSED")
    } finally {
        $c.Close()
    }
}

try {
    $r = Invoke-WebRequest -Uri ("http://" + $ip + ":8080/cgi-bin/luci") -TimeoutSec 8 -UseBasicParsing
    Write-Host ("HTTP8080: " + $r.StatusCode)
} catch {
    Write-Host ("HTTP8080: " + $_.Exception.Message)
}
