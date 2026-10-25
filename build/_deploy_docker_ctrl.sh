#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080

echo "== 落盘 controller =="
tr -d '\r' < /tmp/_up_kp_docker.lua > /usr/lib/lua/luci/controller/kp_docker.lua
chmod 644 /usr/lib/lua/luci/controller/kp_docker.lua
ls -l /usr/lib/lua/luci/controller/kp_docker.lua
lua -e "assert(loadfile('/usr/lib/lua/luci/controller/kp_docker.lua'))" && echo "  语法 OK"

echo "== 落盘 CGI（已移除手工节点）=="
tr -d '\r' < /tmp/_up_luci > "$D/www/cgi-bin/luci"
chmod 755 "$D/www/cgi-bin/luci"
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" && echo "  CGI 语法 OK"
echo -n "  手工节点残留（应为 0）: "; grep -c 'admin.nodes.docker' "$D/www/cgi-bin/luci"

echo "== 清缓存重启 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== 缓存里 Docker 节点 =="
grep -o 'admin/docker' /tmp/luci-indexcache* 2>/dev/null | sort | uniq -c | head -3
echo "== 页面 =="
curl -s -o /dev/null -m 10 -w "  /admin/docker = %{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/docker
echo "== 动作 =="
curl -s -m 10 "http://192.168.66.1:8080/cgi-bin/luci/admin/docker?action=docker&op=info" | head -c 120
echo
