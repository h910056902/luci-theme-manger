#!/bin/sh
echo "== kp8080 残留 =="
ls -l /etc/init.d/kp8080-listen /usr/bin/kp8080-listen 2>/dev/null || echo "  无 kp8080-listen"
ls -l /etc/init.d/kpsmsfwd /usr/bin/kpsmsfwd /etc/init.d/kpswap /etc/init.d/ttyd8080 2>/dev/null
uci show uhttpd 2>/dev/null | grep -E 'openwrt8080|8080' | head -5

echo "== 面板文件抽样 =="
D=/overlay/nradio-apps/openwrt-luci-8080
ls -l "$D/www/cgi-bin/luci"
ls -l "$D/usr/lib/lua/luci/view/admin_status/" 2>/dev/null | awk '{print "  "$5" "$9}' | head -8
ls -l "$D/www/luci-static/bootstrap" 2>/dev/null | head -3

echo "== 内核模块 veth =="
ls /lib/modules/$(uname -r)/ 2>/dev/null | grep -E '^(veth|macvlan|ipvlan)' || echo "  模块目录里无 veth/macvlan"
modprobe veth 2>&1 | head -2
lsmod 2>/dev/null | grep -c veth

echo "== opkg 是否可用 =="
opkg --version 2>&1 | head -2
ls -l /etc/opkg* 2>/dev/null | head -5
ls /etc/apk/repositories 2>/dev/null && head -3 /etc/apk/repositories

echo "== 网络 =="
ip -4 addr 2>/dev/null | grep -E 'inet ' | head -5
