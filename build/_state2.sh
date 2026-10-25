#!/bin/sh
echo "== 设备 =="
cat /tmp/sysinfo/model 2>/dev/null
. /etc/openwrt_release 2>/dev/null
echo "firmware: $DISTRIB_DESCRIPTION"
echo "uptime: $(cat /proc/uptime | cut -d' ' -f1)"
echo "kernel: $(uname -r)"

echo "== /overlay =="
ls -la /overlay/ 2>/dev/null | head -12
echo "== /root =="
ls -la /root/ 2>/dev/null | head -12

echo "== 面板 =="
ls -d /overlay/nradio-apps/openwrt-luci-8080 2>/dev/null || echo "  面板目录不存在"
ls -l /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci 2>/dev/null
opkg list-installed 2>/dev/null | grep -E 'nradio|openclash|ttyd' | head -5

echo "== 服务 =="
netstat -lnt 2>/dev/null | grep -E ':80 |:443|:8080|:7681'
ps w | grep -E '[u]httpd|[t]tyd|[o]penclash' | head -4

echo "== 磁盘 =="
df -h /overlay | tail -1
