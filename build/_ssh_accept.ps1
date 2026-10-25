$ErrorActionPreference = 'Continue'
$plink = 'C:\Program Files\PuTTY\plink.exe'
' y' | & $plink -ssh -pw admin root@192.168.66.1 'echo CONNECTED; cat /tmp/sysinfo/model; . /etc/openwrt_release; echo $DISTRIB_DESCRIPTION' 2>&1 | Select-Object -First 12
