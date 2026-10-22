#!/bin/sh
echo "== uci show kpnet =="
uci show kpnet 2>&1
echo "== 文件 =="
ls -l /etc/config/kpnet 2>&1
cat /etc/config/kpnet 2>/dev/null
echo "== 手动设 all =="
uci set kpnet.web.listen='all' 2>&1
uci set kpnet.web.port='8080' 2>&1
uci commit kpnet 2>&1
uci show kpnet 2>&1
echo "== resolve =="
/usr/bin/kp8080-listen resolve
echo "== 手动 apply =="
/usr/bin/kp8080-listen apply
echo "== 结果 =="
uci -q get uhttpd.openwrt8080.listen_http
netstat -lnt 2>/dev/null | grep 8080
