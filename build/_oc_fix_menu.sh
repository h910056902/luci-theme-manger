#!/bin/sh
echo "== 1. 清菜单缓存 =="
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== 2. 重新探测页面 =="
rm -f /tmp/oc.ck
curl -s -c /tmp/oc.ck -o /dev/null -d 'luci_username=root&luci_password=admin' http://127.0.0.1/cgi-bin/luci/
for p in admin/services/openclash admin/services/openclash/status admin/services/openclash/config admin/services/openclash/client; do
	code=$(curl -s -b /tmp/oc.ck -o /tmp/ocp.html -m 15 -w '%{http_code}' "http://127.0.0.1/cgi-bin/luci/$p")
	echo "  $p -> $code $(wc -c < /tmp/ocp.html 2>/dev/null)B"
done

echo "== 3. 真实转发规则（mangle / nat）=="
echo -n "  mangle 含 7895/7893: "; iptables -t mangle -S 2>/dev/null | grep -cE '7895|7893'
iptables -t mangle -S 2>/dev/null | grep -E '7895|7893' | head -3
echo -n "  nat 含 7893/7895:    "; iptables -t nat -S 2>/dev/null | grep -cE '7893|7895'

echo "== 4. 出口 IP 验证（走 TProxy 端口）=="
curl -s -m 12 --max-time 12 -x http://127.0.0.1:7893 -o /dev/null -w "  7893 mixed: %{http_code}\n" http://www.gstatic.com/generate_204
