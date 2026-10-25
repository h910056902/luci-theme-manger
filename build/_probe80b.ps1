$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'
$base = "http://" + $ip

# 登录页字段
$r = Invoke-WebRequest -Uri ($base + "/cgi-bin/luci") -TimeoutSec 8 -UseBasicParsing
Write-Host ("GET /cgi-bin/luci -> " + $r.StatusCode + " len=" + $r.Content.Length)
$fields = [regex]::Matches($r.Content, 'name="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
Write-Host ("FORM FIELDS: " + ($fields -join ', '))
$title = [regex]::Match($r.Content, '<title>([\s\S]*?)</title>')
Write-Host ("TITLE: " + ($title.Groups[1].Value -replace '\s+',' ').Trim())

# 关键内容判断
foreach ($kw in 'luci_password','login','8080','nradio','argon') {
    $c = ([regex]::Matches($r.Content, [regex]::Escape($kw))).Count
    Write-Host ("  keyword " + $kw + ": " + $c)
}

# 尝试两种登录写法
foreach ($pair in @(
    @{n='luci';  d=@{ luci_username='root'; luci_password='admin' }},
    @{n='plain'; d=@{ username='root'; password='admin' }}
)) {
    try {
        $resp = Invoke-WebRequest -Uri ($base + "/cgi-bin/luci") -Method POST -Body $pair.d -TimeoutSec 10 -UseBasicParsing -MaximumRedirection 0
        $sc = $resp.Headers['Set-Cookie']
        Write-Host ("POST(" + $pair.n + ") -> " + $resp.StatusCode + " set-cookie=" + ($sc -join ';'))
    } catch {
        $resp2 = $_.Exception.Response
        if ($resp2) {
            $sc2 = $resp2.Headers['Set-Cookie']
            Write-Host ("POST(" + $pair.n + ") -> " + [int]$resp2.StatusCode + " set-cookie=" + ($sc2 -join ';'))
        } else {
            Write-Host ("POST(" + $pair.n + ") ERR: " + $_.Exception.Message)
        }
    }
}
