$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'
$base = "http://" + $ip

# 1) 取登录页，看表单字段
$r = Invoke-WebRequest -Uri ($base + "/cgi-bin/luci/") -TimeoutSec 8 -UseBasicParsing
Write-Host ("LOGIN PAGE: " + $r.StatusCode + " len=" + $r.Content.Length)
$m = [regex]::Matches($r.Content, 'name="(luci_[a-z_]+)"')
foreach ($x in $m) { Write-Host ("  field: " + $x.Groups[1].Value) }

# 2) 尝试登录
$body = @{ luci_username = 'root'; luci_password = 'admin' }
try {
    $login = Invoke-WebRequest -Uri ($base + "/cgi-bin/luci/") -Method POST -Body $body -TimeoutSec 10 -UseBasicParsing -SessionVariable sess
    Write-Host ("LOGIN POST: " + $login.StatusCode)
    $cookie = $sess.Cookies.GetCookies($base) | ForEach-Object { $_.Name + "=" + $_.Value }
    Write-Host ("COOKIE: " + ($cookie -join '; '))
} catch {
    Write-Host ("LOGIN ERR: " + $_.Exception.Message)
}

# 3) 用会话取状态页
try {
    $ov = Invoke-WebRequest -Uri ($base + "/cgi-bin/luci/admin/status/overview") -WebSession $sess -TimeoutSec 10 -UseBasicParsing
    Write-Host ("OVERVIEW: " + $ov.StatusCode + " len=" + $ov.Content.Length)
    $keys = 'System','Kernel','Uptime','Load','Memory','Local Time','Firmware'
    foreach ($k in $keys) {
        $mm = [regex]::Matches($ov.Content, [regex]::Escape($k) + '[\s\S]{0,160}?<td[^>]*>([\s\S]{0,120}?)</td>')
        if ($mm.Count -gt 0) {
            $v = ($mm[0].Groups[1].Value -replace '<[^>]+>','' -replace '\s+',' ').Trim()
            Write-Host ("  " + $k + ": " + $v)
        }
    }
} catch {
    Write-Host ("OVERVIEW ERR: " + $_.Exception.Message)
}
