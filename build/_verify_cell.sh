#!/bin/sh
# 用 root 会话直接验证两个新接口（绕开登录页，鉴权逻辑认 sysauth=<sid>）
B="http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"

SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
echo "SID_LEN=${#SID}"
if [ -z "$SID" ]; then
    echo "== 登录失败，原始返回 =="
    ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>&1
    exit 1
fi

rm -f /tmp/kpc-nb.json

echo "== action=stats =="
curl -s -m 15 -H "Cookie: sysauth=$SID" "$B?action=stats" | head -c 1000
echo
echo "== action=cell =="
curl -s -m 30 -H "Cookie: sysauth=$SID" "$B?action=cell" | head -c 1200
echo
echo "== action=neighbor =="
curl -s -m 25 -H "Cookie: sysauth=$SID" "$B?action=neighbor" | head -c 1400
echo
echo "== 页面 =="
curl -s -m 15 -H "Cookie: sysauth=$SID" -o /dev/null -w "page=%{http_code}\n" "$B"
echo "== 邻区画像文件 =="
head -c 400 /tmp/kpc-nb.json 2>/dev/null
echo
echo "== 采样历史条数 =="
grep -o '"t":' /tmp/kpc-cell-hist.json 2>/dev/null | wc -l
