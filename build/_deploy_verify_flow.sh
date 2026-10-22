#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
sh /tmp/_deploy_cell3.sh 2>&1 | head -4
rm -f /tmp/kpc-cell-detail.json

SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
if [ -z "$SID" ]; then echo "登录失败"; exit 1; fi

echo "== serving 流量字段 =="
curl -s -m 20 -H "Cookie: sysauth=$SID" "$B?action=cell" | tr ',' '\n' | grep -E '"(dl|ul|mon|total)"'
echo "== 采样末点（速率应开始有值） =="
tail -c 320 /tmp/kpc-cell-hist.json
echo
echo "DONE"
