$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'
$base = 'http://' + $ip
$jar = Join-Path $PSScriptRoot 'v80_cookies.txt'
Remove-Item $jar -Force -ErrorAction SilentlyContinue

function Hit($url, $method = 'GET', $body = $null, $useJar = $false) {
    $args = @{
        Uri                = $url
        Method             = $method
        TimeoutSec         = 10
        UseBasicParsing    = $true
        MaximumRedirection = 0
    }
    if ($body) { $args['Body'] = $body }
    if ($useJar) { $args['WebSession'] = $sess }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        $r = Invoke-WebRequest @args
        $sw.Stop()
        $len = $r.RawContentLength
        if ($null -eq $len -or $len -lt 0) { $len = $r.Content.Length }
        return [pscustomobject]@{ Code = [int]$r.StatusCode; Len = $len; Ms = $sw.ElapsedMilliseconds; Note = '' }
    } catch {
        $sw.Stop()
        $resp = $_.Exception.Response
        if ($resp) {
            return [pscustomobject]@{ Code = [int]$resp.StatusCode; Len = -1; Ms = $sw.ElapsedMilliseconds; Note = 'redirect/error' }
        }
        return [pscustomobject]@{ Code = 0; Len = -1; Ms = $sw.ElapsedMilliseconds; Note = $_.Exception.Message }
    }
}

Write-Host "=== HTTP :80 ==="
foreach ($p in @('/', '/cgi-bin/luci', '/cgi-bin/luci/', '/luci-static/nradio/', '/does-not-exist')) {
    $r = Hit ($base + $p)
    Write-Host ("  {0,-26} {1,3}  {2,7} ms  len={3}" -f $p, $r.Code, $r.Ms, $r.Len)
}

Write-Host ""
Write-Host "=== 登录链路 ==="
$null = Invoke-WebRequest -Uri ($base + '/cgi-bin/luci/') -Method POST -Body @{ luci_username='root'; luci_password='admin' } -TimeoutSec 10 -UseBasicParsing -SessionVariable sess
$ck = ($sess.Cookies.GetCookies($base) | ForEach-Object { $_.Name + '=' + $_.Value }) -join '; '
Write-Host ("  cookie: " + $(if ($ck) { $ck } else { '(未获取)' }))

foreach ($p in @('/admin/status/overview', '/admin/system/security/', '/cgi-bin/luci/nradio/system/overview')) {
    try {
        $r = Invoke-WebRequest -Uri ($base + $p) -WebSession $sess -TimeoutSec 10 -UseBasicParsing
        $t = [regex]::Match($r.Content, '<title>([\s\S]*?)</title>').Groups[1].Value
        $isLogin = ([regex]::Matches($r.Content, 'luci_password')).Count
        Write-Host ("  {0,-38} {1,3}  len={2,-7} 登录页命中={3}  title={4}" -f $p, [int]$r.StatusCode, $r.RawContentLength, $isLogin, $t.Trim())
    } catch {
        Write-Host ("  " + $p + " -> ERR " + $_.Exception.Message)
    }
}

Write-Host ""
Write-Host "=== HTTPS :443 ==="
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $r = Invoke-WebRequest -Uri ("https://" + $ip + "/") -TimeoutSec 8 -UseBasicParsing -SkipCertificateCheck
    Write-Host ("  https / -> " + [int]$r.StatusCode)
} catch {
    Write-Host ("  https / -> " + $_.Exception.Message)
}
