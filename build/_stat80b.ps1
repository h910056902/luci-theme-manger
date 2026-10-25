$ErrorActionPreference = 'SilentlyContinue'
$ip = '192.168.66.1'
$base = "http://" + $ip

$resp = Invoke-WebRequest -Uri ($base + "/cgi-bin/luci") -Method POST -Body @{ luci_username='root'; luci_password='admin' } -TimeoutSec 10 -UseBasicParsing
$sc = $resp.Headers['Set-Cookie']
if ($sc -is [array]) { $sc = $sc[0] }
$cookie = ($sc -split ';')[0]
Write-Host ("COOKIE: " + $cookie)

function Txt($url) {
    $r = Invoke-WebRequest -Uri $url -Headers @{ Cookie = $cookie } -TimeoutSec 15 -UseBasicParsing
    $h = $r.Content -replace '(?s)<script.*?</script>','' -replace '(?s)<style.*?</style>',''
    $h = $h -replace '<[^>]+>','|'
    $h = [System.Net.WebUtility]::HtmlDecode($h)
    $t = (($h -split '\|') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }) -join ' | '
    return @{ code = $r.StatusCode; len = $r.Content.Length; text = $t }
}

$a = Txt ($base + "/cgi-bin/luci/admin/status/overview")
Write-Host ("OVERVIEW: " + $a.code + " html=" + $a.len)
Write-Host ($a.text.Substring(0, [Math]::Min(1600, $a.text.Length)))
