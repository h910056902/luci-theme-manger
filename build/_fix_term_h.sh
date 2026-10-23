#!/bin/sh
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_term.htm
sed -i 's|#terminal-container{width:auto;height:80vh;|#terminal-container{width:auto;height:auto;|' "$F"
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
echo "== 容器规则 =="
grep -o '#terminal-container{[^}]*}' "$F" | head -3
echo -n "页面: "; curl -s -o /dev/null -w '%{http_code}\n' http://192.168.66.1:8080/cgi-bin/luci/admin/status/terminal
