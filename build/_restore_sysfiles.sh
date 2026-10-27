#!/bin/sh
echo "== 安装系统级文件 =="

mkdir -p /usr/lib/lua/luci/controller
tr -d '\r' < /tmp/_up_ctrl_kp_docker > /usr/lib/lua/luci/controller/kp_docker.lua
chmod 644 /usr/lib/lua/luci/controller/kp_docker.lua

mkdir -p /usr/bin /etc/init.d
tr -d '\r' < /tmp/_up_kpsmsfwd > /usr/bin/kpsmsfwd
tr -d '\r' < /tmp/_up_kpsmsfwd_init > /etc/init.d/kpsmsfwd
chmod 755 /usr/bin/kpsmsfwd /etc/init.d/kpsmsfwd

tr -d '\r' < /tmp/_up_kpswap > /etc/init.d/kpswap
chmod 755 /etc/init.d/kpswap

mkdir -p /lib/upgrade/keep.d
tr -d '\r' < /tmp/_up_keep > /lib/upgrade/keep.d/nradio-luci-8080
chmod 644 /lib/upgrade/keep.d/nradio-luci-8080

echo "== 逐个校验 =="
for f in /usr/lib/lua/luci/controller/kp_docker.lua \
         /usr/bin/kpsmsfwd /etc/init.d/kpsmsfwd /etc/init.d/kpswap \
         /lib/upgrade/keep.d/nradio-luci-8080; do
	if [ -f "$f" ]; then printf "  OK   %7s  %s\n" "$(wc -c < "$f")" "$f"; else printf "  MISS %s\n" "$f"; fi
done

echo "== 语法 =="
lua -e "assert(loadfile('/usr/lib/lua/luci/controller/kp_docker.lua'))" && echo "  controller OK"

echo "== 清缓存重启 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== 探测各页 =="
for p in admin/docker admin/status/details admin/status/cellular admin/status/device admin/status/sms admin/status/terminal; do
	code=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "http://192.168.66.1:8080/cgi-bin/luci/$p")
	echo "  $p -> $code"
done
echo "== docker 接口 =="
curl -s -m 8 "http://192.168.66.1:8080/cgi-bin/luci/admin/docker?action=docker&op=info" | head -c 120
echo
