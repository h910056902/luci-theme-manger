#!/bin/sh
echo "== ubus session login 原始输出 =="
ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>&1 | head -c 400
echo
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
echo "SID=$SID"
echo "== session 列表 =="
ls /tmp/luci-sessions* 2>/dev/null | head -5
echo "== 不带 cookie 访问 =="
curl -s -m 15 -o /dev/null -w "plain http=%{http_code}\n" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/details"
echo "== 带 cookie 访问 =="
curl -s -m 15 -H "Cookie: sysauth=$SID" -o /dev/null -w "cookie http=%{http_code}\n" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/details"
echo "== uhttpd 实例 =="
netstat -lntp 2>/dev/null | grep -E ':8080|:80 ' | head -5
