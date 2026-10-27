#!/bin/sh
echo "== 镜像站点可达性 =="
for u in https://docker.m.daocloud.io/v2/ https://dockerproxy.com/v2/ https://registry-1.docker.io/v2/; do
	code=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "$u")
	echo "  $code  $u"
done

echo "== 面板登录 =="
rm -f /tmp/pn.ck
curl -s -c /tmp/pn.ck -o /dev/null -w "  login=%{http_code}\n" \
	-d 'luci_username=root&luci_password=admin' "http://192.168.66.1:8080/cgi-bin/luci/"

echo "== 页面状态（带会话）=="
for p in admin/status/details admin/status/cellular admin/status/device admin/status/sms admin/status/terminal admin/docker; do
	c=$(curl -s -b /tmp/pn.ck -o /tmp/pg.html -m 10 -w '%{http_code}' "http://192.168.66.1:8080/cgi-bin/luci/$p")
	e=$(grep -c 'Failed to execute template' /tmp/pg.html 2>/dev/null)
	echo "  $p -> $c  errors=$e"
done
