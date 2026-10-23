#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":600}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
[ -n "$SID" ] || { echo "登录失败"; exit 1; }
C="Cookie: sysauth=$SID"

echo "== swap 状态 =="
curl -s -m 20 -H "$C" "$B?action=swap"
echo
echo "== 卡锁状态 =="
curl -s -m 20 -H "$C" "$B?action=simlock"
echo
echo "== 数据分区 =="
ls -ld /mnt/storage/data 2>&1
df -h /mnt/storage/data 2>/dev/null | tail -1
echo "== bdinfo =="
bdinfo -g sim_protect 2>&1
echo "DONE"
