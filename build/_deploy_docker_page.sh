#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)

echo "== 备份 =="
mkdir -p /tmp/kpc-docker-$TS
cp "$D/www/cgi-bin/luci" "/tmp/kpc-docker-$TS/luci" 2>/dev/null
echo "  /tmp/kpc-docker-$TS/"

echo "== 落盘 =="
tr -d '\r' < /tmp/_up_luci > "$D/www/cgi-bin/luci"
chmod 755 "$D/www/cgi-bin/luci"
tr -d '\r' < /tmp/_up_docker.htm > "$V/nradio_docker.htm"
chmod 644 "$V/nradio_docker.htm"

echo "== 校验 =="
echo "  cgi=$(wc -c < "$D/www/cgi-bin/luci")  docker.htm=$(wc -c < "$V/nradio_docker.htm")"
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" && echo "  LUA_SYNTAX_OK"
echo -n "  菜单节点: "; grep -c 'status.nodes.docker' "$D/www/cgi-bin/luci"
echo -n "  白名单:   "; grep -c 'nradio_docker.htm' "$D/www/cgi-bin/luci"
echo -n "  动作登记: "; grep -c 'docker = true' "$D/www/cgi-bin/luci"

echo "== 清缓存并重启 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== 接口冒烟 =="
curl -s -m 10 "http://192.168.66.1:8080/cgi-bin/luci/admin/status/docker?action=docker&op=info" -o /tmp/kd_info.txt -w "  info=%{http_code}\n"
head -c 300 /tmp/kd_info.txt 2>/dev/null; echo
curl -s -o /dev/null -m 8 -w "  page=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/docker
