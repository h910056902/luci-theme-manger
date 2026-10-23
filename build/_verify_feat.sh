#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
[ -n "$SID" ] || { echo "登录失败"; exit 1; }
C="Cookie: sysauth=$SID"

echo "== 1. terminal 状态 =="
curl -s -m 15 -H "$C" "$B?action=terminal"
echo
echo "== 2. hnat 状态 =="
curl -s -m 15 -H "$C" "$B?action=hnat"
echo
echo "== 3. at_raw 带确认 =="
curl -s -m 20 -H "$C" -d "cmd=AT+CSQ&confirm=1" "$B?action=at_raw"
echo
echo "== 4. at_raw 不带确认（应拒绝） =="
curl -s -m 15 -H "$C" -d "cmd=AT+CSQ" "$B?action=at_raw"
echo
echo "== 5. 非 AT 命令（应拒绝） =="
curl -s -m 15 -H "$C" -d "cmd=ls&confirm=1" "$B?action=at_raw"
echo
echo "== 6. 页面关键串 =="
curl -s -m 15 -H "$C" -o /tmp/p.html "$B"
grep -c "网页终端" /tmp/p.html
grep -c "硬件加速" /tmp/p.html
grep -c "AT 高级命令" /tmp/p.html
echo "DONE"
