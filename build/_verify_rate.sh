#!/bin/sh
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
sh /tmp/_deploy_cell3.sh 2>&1 | head -4
rm -f /tmp/kpc-cell-detail.json

SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
if [ -z "$SID" ]; then echo "登录失败"; exit 1; fi

echo "== 采两点（间隔 12s） =="
curl -s -m 20 -H "Cookie: sysauth=$SID" "$B?action=poll" > /dev/null
sleep 12
curl -s -m 20 -H "Cookie: sysauth=$SID" "$B?action=poll" > /dev/null

echo "== 末点字段 =="
tail -c 260 /tmp/kpc-cell-hist.json
echo
echo "== 全文件里非零 dlr 的点数 =="
grep -o '"dlr":[1-9][0-9]*' /tmp/kpc-cell-hist.json | wc -l
echo "DONE"
