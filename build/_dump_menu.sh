#!/bin/sh
echo "== 固件一级菜单（controller entry） =="
grep -ho 'entry({"admin",[^}]*}' /usr/lib/lua/luci/controller/*.lua 2>/dev/null | sort -u | head -30

echo "== 状态相关入口 =="
grep -rn 'status' /usr/lib/lua/luci/controller/*.lua 2>/dev/null | grep 'entry(' | head -20

echo "== nradio 控制器菜单 =="
grep -h 'entry(' /usr/lib/lua/luci/controller/nradio/*.lua 2>/dev/null | head -20

echo "== 8080 是否有私有 controller =="
ls /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/controller/ 2>/dev/null || echo "无（复用系统控制器）"

echo "== 8080 自定义页面如何注册 =="
grep -n 'nradio_cellular\|nradio_details\|nradio_device\|nradio_sms\|nradio_8080' /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci 2>/dev/null | head -20

echo "== 8080 菜单项（如果有硬编码） =="
grep -n 'cell\|nradio' /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/themes/bootstrap/header.htm 2>/dev/null | head -10
