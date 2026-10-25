#!/bin/sh
echo "== 包登记 =="
opkg list-installed 2>/dev/null | grep nradio-luci-8080

echo "== 系统脚本 =="
ls -l /etc/init.d/kp8080-listen /usr/bin/kp8080-listen 2>/dev/null || echo "  缺"
ls -l /etc/rc.d/ | grep -i kp8080 || echo "  未开机自启"

echo "== kpnet =="
uci show kpnet 2>/dev/null

echo "== uhttpd 实例 =="
uci show uhttpd 2>/dev/null | grep -E 'kp8080|8080' | head -10

echo "== 监听 =="
netstat -lnt 2>/dev/null | grep -E ':80 |:8080'

echo "== 本机请求面板 =="
curl -s -o /dev/null -w "  /cgi-bin/luci -> %{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci --max-time 8
curl -s -o /dev/null -w "  /            -> %{http_code}\n" http://192.168.66.1:8080/ --max-time 8
