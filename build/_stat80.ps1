$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'
$base = "http://" + $ip

# 登录拿 cookie
$null = Invoke-WebRequest -Uri ($base + "/cgi-bin/luci") -Method POST -Body @{ luci_username='root'; luci_password='admin' } -TimeoutSec 10 -UseBasicParsing -SessionVariable sess
$cookie = ($sess.Cookies.GetCookies($base) | ForEach-Object { $_.Name + "=" + $_.Value }) -join '; '
Write-Host ("COOKIE: " + $cookie)

function Get-Text($url) {
    $r = Invoke-WebRequest -Uri $url -WebSession $sess -TimeoutSec 12 -UseBasicParsing
    $h = $r.Content -replace '(?s)<script.*?</script>','' -replace '(?s)<style.*?</style>',''
    $h = $h -replace '<[^>]+>','|'
    $h = [System.Net.WebUtility]::HtmlDecode($h)
    $h = ($h -split '\|' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join ' | '
    return @{ code = $r.StatusCode; text = $h; len = $r.Content.Length }
}

$ov = Get-Text ($base + "/cgi-bin/luci/admin/status/overview")
Write-Host ("OVERVIEW: " + $ov.code + " html=" + $ov.len)
Write-Host ("TEXT: " + $ov.text.Substring(0, [Math]::Min(1400, $ov.text.Length)))

Write-Host ""
$sy = Get-Text ($base + "/cgi-bin/luci/admin/system/admin/dropbear")
Write-Host ("DROPBEAR PAGE: " + $sy.code)
Write-Host ("TEXT: " + $sy.text.Substring(0, [Math]::Min(600, $sy.text.Length)))
