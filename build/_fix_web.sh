#!/bin/sh
echo "== 修复前 =="
ls -ld /tmp/luci-sessions 2>/dev/null || echo "  会话目录缺失"
ls -l /tmp/luci-indexcache 2>/dev/null

echo "== 1. 建会话目录 =="
mkdir -p /tmp/luci-sessions
chmod 700 /tmp/luci-sessions
ls -ld /tmp/luci-sessions

echo "== 2. 清陈旧缓存 =="
rm -f /tmp/luci-indexcache
rm -rf /tmp/luci-modulecache
echo "  已清理"

echo "== 3. 重启 uhttpd =="
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
ps w | grep '[u]httpd' | head -2

echo "== 4. 复测登录 =="
rm -f /tmp/cj2.txt
curl -s -c /tmp/cj2.txt -o /tmp/n1.html -w "  GET 登录页=%{http_code} size=%{size_download}\n" http://127.0.0.1/cgi-bin/luci
curl -s -b /tmp/cj2.txt -c /tmp/cj2.txt -o /tmp/n2.html -w "  POST 登录=%{http_code} size=%{size_download}\n" \
	-d "luci_username=root&luci_password=admin" http://127.0.0.1/cgi-bin/luci/
curl -s -b /tmp/cj2.txt -o /tmp/n3.html -w "  GET 总览=%{http_code} size=%{size_download}\n" http://127.0.0.1/cgi-bin/luci/admin/status/overview
echo -n "  总览是否登录页: "; grep -c 'luci_password' /tmp/n3.html
echo -n "  总览标题: "; grep -o '<title>[^<]*' /tmp/n3.html | head -1

echo "== 5. 新索引缓存 =="
ls -l /tmp/luci-indexcache 2>/dev/null || echo "  尚未生成（首次访问后生成）"
echo "== 6. 会话文件 =="
ls -l /tmp/luci-sessions 2>/dev/null | head -3
