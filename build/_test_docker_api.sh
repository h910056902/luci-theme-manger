#!/bin/sh
B=http://192.168.66.1:8080
rm -f /tmp/kd.ck

echo "== 登录 =="
curl -s -c /tmp/kd.ck -o /dev/null -w "  login=%{http_code}\n" \
	-d "luci_username=root&luci_password=admin" "$B/cgi-bin/luci/"

echo "== info =="
curl -s -b /tmp/kd.ck -m 15 "$B/cgi-bin/luci/admin/status/docker?action=docker&op=info" | head -c 400
echo
echo "== ps =="
curl -s -b /tmp/kd.ck -m 15 "$B/cgi-bin/luci/admin/status/docker?action=docker&op=ps" | head -c 400
echo
echo "== images =="
curl -s -b /tmp/kd.ck -m 15 "$B/cgi-bin/luci/admin/status/docker?action=docker&op=images" | head -c 400
echo
echo "== 页面里 URL 变量 =="
curl -s -b /tmp/kd.ck -m 15 "$B/cgi-bin/luci/admin/status/docker" | grep -o "var URL = '[^']*'" | head -1
echo "== 页面里是否含 kd-state =="
curl -s -b /tmp/kd.ck -m 15 "$B/cgi-bin/luci/admin/status/docker" | grep -c 'kd-state'
