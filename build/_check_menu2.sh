#!/bin/sh
echo "== 一级菜单（系统控制器 entry 的首段） =="
grep -rho 'entry({"admin", *"[a-z_0-9]*"' /usr/lib/lua/luci/controller/ 2>/dev/null \
    | sed 's/.*"admin", *"//; s/"$//' | sort | uniq -c | sort -rn | head -20

echo "== menu.d 里的菜单定义 =="
ls /usr/share/luci/menu.d/ 2>/dev/null | head -20
grep -ho '"title": *"[^"]*"' /usr/share/luci/menu.d/*.json 2>/dev/null | sort -u | head -20

echo "== 8080 CGI 注入的菜单节点 =="
grep -n 'title = "' /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci | head -15

echo "== header.htm 主动隐藏的项 =="
grep -n "indexOf('/network/diagnostics')" /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/themes/bootstrap/header.htm | head -3

echo "== luci 菜单相关开关 =="
uci -q get luci.main.appcenter_menu
uci -q get luci.main.mediaurlbase

echo "== 80 端口实例的 uhttpd home（是否同一套控制器） =="
uci -q get uhttpd.main.home
