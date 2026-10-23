#!/bin/sh
echo "== 一级页面 entry 及其 order =="
grep -rhoE 'entry\(\{"admin", "[a-z_0-9]+"\}(, *alias\([^)]*\))?, *_?\(?"[^"]*"?\)?, *[0-9]+' \
    /usr/lib/lua/luci/controller/*.lua 2>/dev/null | sed 's/, */ /g' | head -25

echo "== menu.d/quickstart =="
cat /usr/share/luci/menu.d/luci-app-quickstart.json 2>/dev/null
echo "== menu.d/istorerouter =="
head -c 400 /usr/share/luci/menu.d/luci-app-istorerouter.json 2>/dev/null
echo
echo "== 8080 里「首页」节点与 menu.d 是否冲突 =="
grep -c 'admin.nodes.quickstart' /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci
