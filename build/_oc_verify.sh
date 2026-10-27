#!/bin/sh
echo "== 1. 订阅节点 =="
f=/etc/openclash/e_bbydy.yaml
[ -f "$f" ] || f=/etc/openclash/config/e_bbydy.yaml
echo "  file=$f size=$(wc -c < "$f" 2>/dev/null)"
echo "  proxies 行: $(grep -c '^ *- name:' "$f" 2>/dev/null)"
grep -m3 '^ *- name:' "$f" 2>/dev/null

echo "== 2. 代理连通性 =="
echo -n "  gstatic204 via 7890: "
curl -s -o /dev/null -m 12 -x http://127.0.0.1:7890 -w '%{http_code}\n' http://www.gstatic.com/generate_204
echo -n "  github via 7890:     "
curl -s -o /dev/null -m 20 -x http://127.0.0.1:7890 -w '%{http_code}\n' https://github.com
echo -n "  直连百度:            "
curl -s -o /dev/null -m 10 -w '%{http_code}\n' http://www.baidu.com

echo "== 3. 防火墙重定向规则 =="
iptables -t nat -S 2>/dev/null | grep -c 7890
iptables -t nat -S 2>/dev/null | grep 7890 | head -3

echo "== 4. 自启与守护 =="
ls /etc/rc.d/ | grep -i openclash
crontab -l 2>/dev/null | grep -ci openclash

echo "== 5. LuCI 页面 =="
rm -f /tmp/oc.ck
curl -s -c /tmp/oc.ck -o /dev/null -d 'luci_username=root&luci_password=admin' http://127.0.0.1/cgi-bin/luci/
curl -s -b /tmp/oc.ck -o /tmp/ocpage.html -m 15 -w "  80 openclash 页: %{http_code} %{size_download}B\n" \
	http://127.0.0.1/cgi-bin/luci/admin/services/openclash/status
grep -c 'Failed to execute' /tmp/ocpage.html 2>/dev/null
