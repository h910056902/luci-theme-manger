#!/bin/sh
echo "== 1. 日志位置 =="
ls -l /etc/openclash/*.log /tmp/openclash.log 2>/dev/null | head -5
echo "-- logread 里 openclash 相关 --"
logread 2>/dev/null | grep -i openclash | tail -8

echo "== 2. iptables 现状 =="
iptables -t nat -S 2>/dev/null | head -8
echo "  mangle:"
iptables -t mangle -S 2>/dev/null | head -5
echo "  OPENCLASH 链:"
iptables -t nat -L OPENCLASH -n 2>/dev/null | head -5 || echo "  无 OPENCLASH 链"

echo "== 3. 路由标记 =="
ip rule list 2>/dev/null | head -6
ip route show table all 2>/dev/null | grep -c 'default'

echo "== 4. 关键脚本是否存在 =="
ls /usr/share/openclash/ 2>/dev/null | head -12

echo "== 5. 当前运行模式 =="
uci show openclash 2>/dev/null | grep -E 'en_mode|proxy_mode|redir|tun|dns_|router_self' | head -8

echo "== 6. LuCI 页面路径 =="
rm -f /tmp/oc.ck
curl -s -c /tmp/oc.ck -o /dev/null -d 'luci_username=root&luci_password=admin' http://127.0.0.1/cgi-bin/luci/
for p in admin/services/openclash admin/services/openclash/status admin/services/openclash/config; do
	code=$(curl -s -b /tmp/oc.ck -o /tmp/ocp.html -m 12 -w '%{http_code}' "http://127.0.0.1/cgi-bin/luci/$p")
	echo "  $p -> $code $(wc -c < /tmp/ocp.html 2>/dev/null)B"
done
