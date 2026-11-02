#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
echo "== 8080 主题相关 uci =="
uci show luci 2>/dev/null | grep -iE 'theme|mediaurl|8080' | head -10
echo
echo "== myos / c2000max-ui 在 CGI 里的引用 =="
grep -n 'myos\|c2000max' $D/www/cgi-bin/luci 2>/dev/null | head -12
echo
echo "== 改动文件 mtime =="
for f in usr/lib/lua/luci/view/admin_status/nradio_details.htm usr/lib/lua/luci/view/admin_status/nradio_docker.htm usr/lib/lua/luci/view/admin_status/nradio_term.htm usr/lib/lua/luci/view/istorerouter/main.htm usr/lib/lua/luci/view/quickstart/main.htm usr/lib/lua/luci/view/themes/bootstrap/header.htm www/cgi-bin/luci usr/lib/lua/luci/view/admin_status/myos_home.htm usr/lib/lua/luci/view/admin_status/myos_ui.htm; do
  ls -l "$D/$f" 2>/dev/null | awk '{print $5, $6, $7, $8, $9}'
done
echo
echo "== myos_home / myos_ui 头部特征 =="
head -12 $D/usr/lib/lua/luci/view/admin_status/myos_home.htm 2>/dev/null
echo "---"
head -12 $D/usr/lib/lua/luci/view/admin_status/myos_ui.htm 2>/dev/null
echo
echo "== c2000max-ui 入口规模 =="
ls -l $D/www/luci-static/c2000max-ui/*.css $D/www/luci-static/c2000max-ui/*.js 2>/dev/null | awk '{print $5, $9}' | head -15
echo
echo "== 首页 index.htm 现在指向什么 =="
head -20 $D/usr/lib/lua/luci/view/admin_status/index.htm 2>/dev/null
