$ErrorActionPreference = 'Continue'
$hk = 'SHA256:+YA3wBuwchbSg6Cp7Rlsj7Bf1HHTHzXx5OkDLbqANeo'
$host_ = 'root@192.168.66.1'
$pscp = 'C:\Program Files\PuTTY\pscp.exe'
$plink = 'C:\Program Files\PuTTY\plink.exe'
$root = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager'

$map = @(
    @{ src = "$root\usr\lib\lua\luci\controller\kp_docker.lua"; dst = '/tmp/_up_ctrl_kp_docker' },
    @{ src = "$root\usr\bin\kpsmsfwd";                            dst = '/tmp/_up_kpsmsfwd' },
    @{ src = "$root\etc\init.d\kpsmsfwd";                          dst = '/tmp/_up_kpsmsfwd_init' },
    @{ src = "$root\etc\init.d\kpswap";                            dst = '/tmp/_up_kpswap' },
    @{ src = "$root\build\keep-nradio-8080";                       dst = '/tmp/_up_keep' },
    @{ src = "$root\build\_restore_sysfiles.sh";                   dst = '/tmp/_restore_sysfiles.sh' }
)

foreach ($m in $map) {
    if (-not (Test-Path $m.src)) { Write-Host ("MISS LOCAL " + $m.src); continue }
    & $pscp -scp -batch -hostkey $hk -pw admin $m.src ($host_ + ':' + $m.dst) 2>&1 | Out-Null
}
Write-Host 'uploaded'
