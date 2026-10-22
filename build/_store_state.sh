#!/bin/sh
echo "== ubus 中的本应用 =="
ubus call appcenter list 2>/dev/null | grep -B2 -A10 "nradio-luci-8080" | head -40
echo "== uci 中的本应用 =="
uci show appcenter 2>/dev/null | grep -n "nradio-luci-8080"
echo "== 条目数 =="
ubus call appcenter list 2>/dev/null | grep -c "nradio-luci-8080"
echo "== opkg =="
opkg list-installed | grep nradio-luci
echo "== 8080 =="
curl -s -m 8 -o /dev/null -w "/ -> %{http_code}\n" http://192.168.66.1:8080/
curl -s -m 8 -o /dev/null -w "details -> %{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci/admin/status/details
