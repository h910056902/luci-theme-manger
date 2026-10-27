$ErrorActionPreference = 'Continue'
$hk = 'SHA256:+YA3wBuwchbSg6Cp7Rlsj7Bf1HHTHzXx5OkDLbqANeo'
$host_ = 'root@192.168.66.1'
$pscp = 'C:\Program Files\PuTTY\pscp.exe'
$plink = 'C:\Program Files\PuTTY\plink.exe'
$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager'

$map = @(
    @{ src = "$root\usr\bin\kp-recovery";                          dst = '/tmp/_up_kprec' },
    @{ src = "$root\usr\lib\lua\luci\controller\kp_recovery.lua";  dst = '/tmp/_up_kprec_ctrl' },
    @{ src = "$root\usr\lib\lua\luci\view\kp_recovery\main.htm";   dst = '/tmp/_up_kprec_view' },
    @{ src = "$root\build\_deploy_recovery.sh";                     dst = '/tmp/_deploy_recovery.sh' }
)

foreach ($m in $map) {
    if (-not (Test-Path $m.src)) { Write-Host ("MISS_LOCAL " + $m.src); continue }
    & $pscp -scp -batch -hostkey $hk -pw admin $m.src ($host_ + ':' + $m.dst) 2>&1 | Out-Null
}
Write-Host 'uploaded'

& $plink -ssh -batch -hostkey $hk -pw admin $host_ 'sh /tmp/_deploy_recovery.sh 2>&1'
