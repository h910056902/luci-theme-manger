#!/bin/sh
B=http://127.0.0.1

echo "== 403 页面里有没有登录表单 =="
curl -s -o /tmp/p403.html "$B/cgi-bin/luci"
echo -n "  含 luci_password: "; grep -c 'luci_password' /tmp/p403.html
echo -n "  含 login: "; grep -c 'login' /tmp/p403.html
echo -n "  标题: "; grep -o '<title>[^<]*' /tmp/p403.html | head -1

echo "== 会话目录 =="
ls -ld /tmp/luci-sessions 2>/dev/null || echo "  无 /tmp/luci-sessions"
ls -ld /tmp/luci-indexcache 2>/dev/null || echo "  无 indexcache"

echo "== 登录 =="
rm -f /tmp/cj.txt
curl -s -c /tmp/cj.txt -o /tmp/l1.html -w "  login post=%{http_code} size=%{size_download}\n" \
	-d "luci_username=root&luci_password=admin" "$B/cgi-bin/luci/"
echo -n "  登录页含错误提示: "; grep -c -i 'invalid\|错误' /tmp/l1.html
echo "  cookie:"; cat /tmp/cj.txt | grep -v '^#' | head -3

echo "== 带会话访问 =="
curl -s -b /tmp/cj.txt -o /tmp/l2.html -w "  GET / =%{http_code} size=%{size_download}\n" "$B/cgi-bin/luci/"
curl -s -b /tmp/cj.txt -o /tmp/l3.html -w "  GET overview=%{http_code} size=%{size_download}\n" "$B/cgi-bin/luci/admin/status/overview"
echo -n "  内容片段: "; head -c 200 /tmp/l3.html | tr -d '\n' | cut -c1-160

echo
echo "== dispatcher 报错 =="
logread 2>/dev/null | grep -iE 'dispatcher|template|error' | tail -6
