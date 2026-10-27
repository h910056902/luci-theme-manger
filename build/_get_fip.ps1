$ErrorActionPreference = 'Continue'
$hk = 'SHA256:+YA3wBuwchbSg6Cp7Rlsj7Bf1HHTHzXx5OkDLbqANeo'
$pscp = 'C:\Program Files\PuTTY\pscp.exe'
$dst = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\_uboot'

New-Item -ItemType Directory -Force $dst | Out-Null

foreach ($f in @('_fip.bin', '_bl2.bin', '_env.bin')) {
    $local = Join-Path $dst ($f -replace '^_', '' -replace '\.bin$', '.bin')
    & $pscp -scp -batch -hostkey $hk -pw admin ("root@192.168.66.1:/tmp/" + $f) $local 2>&1 | Out-Null
}

Get-ChildItem $dst | Select-Object Name, Length | Format-Table -AutoSize
