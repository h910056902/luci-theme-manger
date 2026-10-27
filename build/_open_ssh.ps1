$ErrorActionPreference = 'Continue'
$ip = '192.168.66.1'
$base = 'http://' + $ip
$work = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build'
$ck = Join-Path $work 'ssh_ck.txt'
$sec = Join-Path $work 'ssh_sec.html'
$applyVal = 'Save ' + [char]38 + ' Apply'

Remove-Item $ck -Force -ErrorAction SilentlyContinue

Write-Host '== 1. login 80 =='
curl.exe -s -c $ck -o (Join-Path $work 'ssh_login.html') -w '  login=%{http_code} size=%{size_download}' -d 'luci_username=root' -d 'luci_password=admin' ($base + '/cgi-bin/luci/')
Write-Host ''

Write-Host '== 2. security page =='
curl.exe -s -b $ck -o $sec -w '  security=%{http_code} size=%{size_download}' ($base + '/cgi-bin/luci/admin/system/security/')
Write-Host ''

$html = Get-Content $sec -Raw -Encoding UTF8
$tok = [regex]::Match($html, 'name="token"\s+value="([^"]+)"').Groups[1].Value
Write-Host ('  token=' + $tok)

$sel = [regex]::Match($html, 'cbid\.firewall\.ssh\.target[\s\S]{0,600}?</select>').Value
if ($sel -match 'value="ACCEPT"[^>]*selected') { $cur = 'ACCEPT' }
elseif ($sel -match 'value="REJECT"[^>]*selected') { $cur = 'REJECT' }
else { $cur = 'UNKNOWN' }
Write-Host ('  current=' + $cur)

if ($cur -eq 'ACCEPT') {
    Write-Host '  already ACCEPT'
} else {
    Write-Host '== 3. set ACCEPT =='
    $code = curl.exe -s -b $ck -o (Join-Path $work 'ssh_post.html') -w '%{http_code}' -F ('token=' + $tok) -F 'cbi.submit=1' -F 'cbid.firewall.ssh.target=ACCEPT' -F ('cbi.apply=' + $applyVal) ($base + '/cgi-bin/luci/admin/system/security/')
    Write-Host ('  post=' + $code)

    curl.exe -s -b $ck -o (Join-Path $work 'ssh_sec2.html') ($base + '/cgi-bin/luci/admin/system/security/')
    $html2 = Get-Content (Join-Path $work 'ssh_sec2.html') -Raw -Encoding UTF8
    $sel2 = [regex]::Match($html2, 'cbid\.firewall\.ssh\.target[\s\S]{0,600}?</select>').Value
    if ($sel2 -match 'value="ACCEPT"[^>]*selected') { Write-Host '  after=ACCEPT' } else { Write-Host '  after=NOT_ACCEPT' }
}

Write-Host '== 4. test 22 =='
Start-Sleep -Seconds 2
$ok = Test-NetConnection -ComputerName $ip -Port 22 -InformationLevel Quiet -WarningAction SilentlyContinue
Write-Host ('  PORT22=' + $ok)
