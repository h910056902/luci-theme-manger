#!/bin/sh
echo "===== 固件 ====="
cat /tmp/sysinfo/model 2>/dev/null
. /etc/openwrt_release 2>/dev/null
echo "fw: $DISTRIB_DESCRIPTION"
echo "kernel: $(uname -r)  uptime: $(cut -d' ' -f1 /proc/uptime)s"

echo "===== 面板 ====="
ls -d /overlay/nradio-apps/openwrt-luci-8080 2>/dev/null || echo "  面板目录不存在"
ls -l /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci 2>/dev/null
ls -l /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/*.htm 2>/dev/null | head -8
opkg list-installed 2>/dev/null | grep -E 'nradio-luci-8080|openclash|ocspeed|ttyd' | head -8

echo "===== 服务/端口 ====="
netstat -lnt 2>/dev/null | grep -E ':80 |:443|:8080|:7681|:7890|:9090'

echo "===== ocspeed 相关 ====="
opkg list-installed 2>/dev/null | grep -iE 'ocspeed|netcheck|speedtest' || echo "  未安装 ocspeed"
ls -l /usr/bin/*ocspeed* /etc/init.d/*ocspeed* /etc/config/ocspeed 2>/dev/null
uci show ocspeed 2>/dev/null | head -10
ls -l /www/luci-static/resources/view/ocspeed 2>/dev/null | head -3
grep -rl ocspeed /usr/lib/lua/luci/controller/ /usr/share/luci/menu.d/ 2>/dev/null | head -5

echo "===== OpenClash ====="
ls -l /etc/openclash/core/clash_meta 2>/dev/null
ps w | grep -E '[c]lash' | head -2

echo "===== 存储 ====="
df -h /overlay | tail -1
