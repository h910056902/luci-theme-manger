#!/bin/sh
echo "== 所有 admin/status 入口 =="
grep -rh 'entry({"admin", *"status"' /usr/lib/lua/luci/controller/ 2>/dev/null | sed 's/^\s*//' | head -30

echo "== status.lua 全文入口 =="
grep -h 'entry(' /usr/lib/lua/luci/controller/admin/status.lua 2>/dev/null | sed 's/^\s*//'

echo "== 8080 header 的菜单后处理（400-445 行） =="
sed -n '400,445p' /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/themes/bootstrap/header.htm

echo "== 8080 自定义页注册（200-240 行） =="
sed -n '200,240p' /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci
