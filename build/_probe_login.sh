#!/bin/sh
echo "== redirect =="
curl -s -i -m 8 "http://192.168.66.1:8080/cgi-bin/luci" | head -8
echo "== sysauth 页 =="
curl -s -m 8 -o /tmp/login.html -w "code=%{http_code}\n" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/nradio_8080_sysauth"
grep -o 'action="[^"]*"' /tmp/login.html | head -3
grep -o 'name="[^"]*"' /tmp/login.html | head -6
echo "== CGI 里的鉴权实现 =="
grep -n "sysauth\|cookie\|session" /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci | head -12
echo "== session 目录 =="
ls -l /tmp/luci-sessions 2>/dev/null | head -5
ls -l /tmp/luci-sessions-8080 2>/dev/null | head -5
