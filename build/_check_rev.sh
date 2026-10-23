#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview"
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":600}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
[ -n "$SID" ] || { echo "登录失败"; exit 1; }
curl -s -m 15 -H "Cookie: sysauth=$SID" "$B?action=kp_status" | tr ',' '\n' \
    | grep -E '"(revision|model|tac|cqi|imei|operator)"'
