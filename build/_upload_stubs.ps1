$ErrorActionPreference = 'Continue'
$pscp = 'C:\Program Files\PuTTY\pscp.exe'
$plink = 'C:\Program Files\PuTTY\plink.exe'
$hk = 'SHA256:66RpOE4kXKmaxFdKh4czcTQI5gME54QWVKjxu1/yNhs'
$src = 'c:\Users\91005\Documents\deepseek-harness\default-workspace\luci-theme-manager\build\_docker'

& $plink -ssh -batch -hostkey $hk -pw admin root@192.168.66.1 'mkdir -p /tmp/dockerstubs && echo dir_ready'

$names = @('kmod-veth', 'kmod-dm', 'kmod-nf-ipvs', 'kmod-br-netfilter', 'kmod-fs-btrfs', 'kmod-ikconfig')
foreach ($n in $names) {
    $file = Join-Path $src ($n + '_5.4.281-1_aarch64_cortex-a53.ipk')
    $dst = 'root@192.168.66.1:/tmp/dockerstubs/' + $n + '_5.4.281-1_aarch64_cortex-a53.ipk'
    & $pscp -scp -batch -hostkey $hk -pw admin $file $dst 2>&1 | Out-Null
}

& $plink -ssh -batch -hostkey $hk -pw admin root@192.168.66.1 'ls -l /tmp/dockerstubs'
