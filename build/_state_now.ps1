$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'

Write-Host ("PING  : " + (Test-Connection -ComputerName $ip -Count 2 -Quiet))
foreach ($p in 22, 80, 8080) {
    Write-Host ("PORT " + $p + ": " + (Test-NetConnection -ComputerName $ip -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue))
}

function Try-Url($u) {
    try {
        $r = Invoke-WebRequest -Uri $u -TimeoutSec 8 -UseBasicParsing
        Write-Host ("  " + $u + " -> " + $r.StatusCode + " len=" + $r.Content.Length)
        return $r
    } catch {
        Write-Host ("  " + $u + " -> ERR " + $_.Exception.Message)
        return $null
    }
}

Write-Host "HTTP:"
$null = Try-Url ("http://" + $ip + "/")
$null = Try-Url ("http://" + $ip + "/cgi-bin/luci")
$null = Try-Url ("http://" + $ip + "/cgi-bin/luci/")

# 尝试登录
try {
    $resp = Invoke-WebRequest -Uri ("http://" + $ip + "/cgi-bin/luci") -Method POST -Body @{ luci_username='root'; luci_password='admin' } -TimeoutSec 10 -UseBasicParsing
    $sc = $resp.Headers['Set-Cookie']
    Write-Host ("LOGIN: " + $resp.StatusCode + " cookie=" + ([string]$sc).Substring(0, [Math]::Min(60, ([string]$sc).Length)))
} catch {
    Write-Host ("LOGIN: ERR " + $_.Exception.Message)
}
