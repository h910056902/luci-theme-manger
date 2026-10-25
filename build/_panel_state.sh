#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080

echo "== 面板目录 =="
du -sm "$D" 2>/dev/null
ls -l "$D/www/cgi-bin/luci" 2>/dev/null || echo "  缺 cgi"
ls -d "$D/usr/lib/lua/luci/view/admin_status" 2>/dev/null || echo "  缺 view 目录"
ls -l "$D/usr/lib/lua/luci/view/admin_status/"*.htm 2>/dev/null | head -8

echo "== 初始化脚本 =="
ls -l /etc/init.d/kp8080-listen /usr/bin/kp8080-listen 2>/dev/null || echo "  缺 kp8080-listen"
ls /etc/init.d/ | grep -i kp

echo "== 8080 实例配置 =="
uci show uhttpd 2>/dev/null | grep -E '8080|instance|nradio' | head -12
grep -n '8080' /etc/config/uhttpd 2>/dev/null | head -10

echo "== 当前 uhttpd 进程 =="
ps w | grep '[u]httpd'

echo "== 监听 =="
netstat -lnt 2>/dev/null | grep -E ':80 |:8080'

echo "== kpnet 配置 =="
uci show kpnet 2>/dev/null | head -8
