#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
[ -n "$SID" ] || { echo "登录失败"; exit 1; }

echo "== 1. 读取现状 =="
curl -s -m 15 -H "Cookie: sysauth=$SID" "$B?action=web_listen" | head -c 900
echo

echo "== 2. 切到 all（0.0.0.0:8080） =="
curl -s -m 15 -H "Cookie: sysauth=$SID" -d "mode=all&port=8080" "$B?action=web_listen_apply"
echo
sleep 8
netstat -lnt 2>/dev/null | grep 8080
uci -q get uhttpd.openwrt8080.listen_http

echo "== 3. 切回 auto =="
curl -s -m 15 -H "Cookie: sysauth=$SID" -d "mode=auto&port=8080" "$B?action=web_listen_apply"
echo
sleep 8
netstat -lnt 2>/dev/null | grep 8080
uci -q get uhttpd.openwrt8080.listen_http

echo "== 4. 非法地址应被拒绝 =="
curl -s -m 15 -H "Cookie: sysauth=$SID" -d "mode=custom&ip=192.168.100.1&port=8080" "$B?action=web_listen_apply"
echo

echo "== 5. 执行日志 =="
cat /tmp/kp8080-listen.log 2>/dev/null
echo "DONE"
