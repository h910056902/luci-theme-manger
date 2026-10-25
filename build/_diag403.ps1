$ErrorActionPreference = 'Continue'
$plink = 'C:\Program Files\PuTTY\plink.exe'
$cmd = 'cat /tmp/sysinfo/model; . /etc/openwrt_release; echo "FW=$DISTRIB_DESCRIPTION"; uptime; echo "== uhttpd =="; ps w | grep "[u]httpd" | head -5; echo "== www =="; ls -l /www/cgi-bin/luci 2>/dev/null; echo "== luci cfg =="; uci show luci 2>/dev/null | head -12; echo "== uhttpd cfg =="; uci show uhttpd 2>/dev/null | head -20; echo "== log =="; logread 2>/dev/null | tail -12'
' y' | & $plink -ssh -pw admin root@192.168.66.1 $cmd 2>&1
