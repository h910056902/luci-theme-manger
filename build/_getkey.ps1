$ErrorActionPreference = 'Continue'
$ip = '192.168.66.1'
$log = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\_plink_v.log'

# 不用 -batch，用管道喂 n（不保存），只看指纹
'n' | & 'C:\Program Files\PuTTY\plink.exe' -v -ssh -pw admin root@$ip 'echo ok' *>&1 | Out-File -FilePath $log -Encoding UTF8
Get-Content $log -Encoding UTF8 | Select-String -Pattern 'SHA256|fingerprint|Host key' | Select-Object -First 6 | ForEach-Object { Write-Host ("  " + $_.Line.Trim()) }
