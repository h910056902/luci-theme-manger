#!/bin/sh
echo "== 固件 =="
cat /tmp/sysinfo/model 2>/dev/null
. /etc/openwrt_release 2>/dev/null
echo "  $DISTRIB_DESCRIPTION"
echo "  kernel=$(uname -r) uptime=$(cut -d' ' -f1 /proc/uptime)s"

echo "== overlay =="
ls -d /overlay/nradio-apps/openwrt-luci-8080 2>/dev/null || echo "  面板目录不存在"
df -h /overlay 2>/dev/null | tail -1

echo "== 已装相关包 =="
opkg list-installed 2>/dev/null | grep -E '^(nradio-luci-8080|dockerd|docker|containerd|runc|ttyd|luci-app-openclash)' | head -10

echo "== 端口 =="
netstat -lnt 2>/dev/null | grep -E ':80 |:443|:8080|:7681|:7890|:9090'

echo "== 源 =="
grep -E 'SNAPSHOT|21\.02\.7' /etc/opkg/distfeeds.conf | head -3

echo "== docker 现状 =="
command -v docker && docker version --format '{{.Server.Version}}' 2>/dev/null
ls -l /etc/docker/daemon.json 2>/dev/null
