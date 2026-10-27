$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'

Write-Host ("PING : " + (Test-Connection -ComputerName $ip -Count 2 -Quiet))
foreach ($p in @(22, 80, 443, 8080, 7681)) {
    $ok = Test-NetConnection -ComputerName $ip -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue
    Write-Host ("PORT " + $p + ": " + $ok)
}

Write-Host "`n--- HTTP 80 版本 ---"
try {
    $r = Invoke-WebRequest -Uri ("http://" + $ip + "/cgi-bin/luci") -TimeoutSec 8 -UseBasicParsing
    $m = [regex]::Match($r.Content, 'OpenWrt[^<]{0,60}')
    Write-Host ("  status=" + [int]$r.StatusCode + "  " + $m.Value)
} catch {
    $resp = $_.Exception.Response
    if ($resp) {
        $sr = New-Object IO.StreamReader($resp.GetResponseStream())
        $body = $sr.ReadToEnd()
        $m = [regex]::Match($body, 'OpenWrt[^<]{0,60}')
        Write-Host ("  status=" + [int]$resp.StatusCode + "  " + $m.Value)
    } else { Write-Host ("  ERR " + $_.Exception.Message) }
}

Write-Host "`n--- SSH 主机密钥探测 ---"
$keys = @(
    'SHA256:66RpOE4kXKmaxFdKh4czcTQI5gME54QWVKjxu1/yNhs',
    'SHA256:ZVq/C69XttXg6Y9eGG0YbAiiw1pZq79vErrOahS12Ks'
)
foreach ($k in $keys) {
    $out = & 'C:\Program Files\PuTTY\plink.exe' -ssh -batch -hostkey $k -pw admin root@$ip 'echo SSH_OK' 2>&1
    if ($out -match 'SSH_OK') { Write-Host ("  OK   " + $k); break }
    else { Write-Host ("  FAIL " + $k) }
}
