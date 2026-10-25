#!/bin/sh
echo "== 清理前的缓存 =="
ls -l /tmp/luci-indexcache* 2>/dev/null
echo -n "缓存里 kaiplus 命中: "; grep -c kaiplus /tmp/luci-indexcache* 2>/dev/null | head -1

echo "== 清缓存 =="
rm -f /tmp/luci-indexcache*
rm -rf /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== 触发一次树构建 =="
curl -s -o /dev/null -m 12 "http://192.168.66.1:8080/cgi-bin/luci/admin/services/kaiplus"
sleep 1
curl -s -o /dev/null -m 12 "http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview"
sleep 1

echo "== 清理后的缓存 =="
ls -l /tmp/luci-indexcache* 2>/dev/null
for f in /tmp/luci-indexcache*; do
	[ -f "$f" ] || continue
	echo -n "$f kaiplus 命中: "; grep -o kaiplus "$f" | wc -l
done

echo "== 直接请求 kaiplus 页 =="
curl -s -o /tmp/kp.html -w "code=%{http_code} size=%{size_download}\n" -m 12 \
	"http://192.168.66.1:8080/cgi-bin/luci/admin/services/kaiplus"
echo -n "是否提示未注册: "; grep -c 'no page is registered\|未注册' /tmp/kp.html
