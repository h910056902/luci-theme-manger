#!/bin/sh
echo "== 包管理器 =="
command -v apk && apk --version 2>/dev/null | head -1
command -v opkg || echo "  无 opkg"

echo "== Lua / ucode =="
command -v lua || echo "  无 lua"
command -v ucode || echo "  无 ucode"
ls -d /usr/lib/lua/luci 2>/dev/null || echo "  无 /usr/lib/lua/luci"

echo "== 面板目录 =="
D=/overlay/nradio-apps/openwrt-luci-8080
ls -la "$D" 2>/dev/null | head -8
ls -l "$D/www/cgi-bin/luci" 2>/dev/null || echo "  无 CGI"

echo "== 关键配置 =="
for f in /etc/config/kpnet /etc/config/ttyd /etc/config/openclash /etc/config/dockerd /etc/docker/daemon.json; do
	[ -f "$f" ] && echo "  OK   $f" || echo "  MISS $f"
done

echo "== docker / veth =="
command -v docker || echo "  无 docker"
ip link add kv0 type veth peer name kv1 2>&1 | head -2
ip link del kv0 2>/dev/null
ls /lib/modules/$(uname -r)/ 2>/dev/null | grep -E 'veth|macvlan' | head -3

echo "== 存储 =="
df -h /overlay | tail -1
echo "== 已装包抽样 =="
apk info 2>/dev/null | head -5
