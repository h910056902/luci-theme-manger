#!/bin/sh
echo "== QuickStart 的 zh_cn 翻译 =="
grep -ra "QuickStart" /usr/lib/lua/luci/i18n/ 2>/dev/null | head -3

echo "== CGI 240-300（首页 / 网络设置向导） =="
sed -n '240,275p' /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci

echo "== CGI 400-440（插件 / 服务 分组） =="
sed -n '400,440p' /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci
