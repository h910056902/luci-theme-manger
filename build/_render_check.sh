#!/bin/sh
echo "== 会话存储位置 =="
ls -d /tmp/luci-sessions 2>/dev/null || echo "无 /tmp/luci-sessions"
ls -1 /tmp/luci-sessions 2>/dev/null | head -3
uci -q get luci.main.sessionpath 2>/dev/null
echo "== sauth 实现 =="
grep -n 'sessionpath' /usr/lib/lua/luci/sauth.lua 2>/dev/null | head -3

echo "== 造一个会话文件 =="
mkdir -p /tmp/luci-sessions
SID=0123456789abcdef0123456789abcdef
printf 'user=root\n' > "/tmp/luci-sessions/$SID"
chmod 600 "/tmp/luci-sessions/$SID"
ls -l "/tmp/luci-sessions/$SID"

echo "== 用该会话取终端页 =="
curl -s -o /tmp/t.html -w "code=%{http_code} size=%{size_download}\n" -m 15 \
	-H "Cookie: sysauth=$SID" \
	"http://192.168.66.1:8080/cgi-bin/luci/admin/status/terminal"

echo -n "是否登录页: "; grep -c 'luci_password' /tmp/t.html
echo -n "含工具栏 kpt-bar: "; grep -c 'kpt-bar' /tmp/t.html
echo -n "含容器 kpt-term: "; grep -c 'id="kpt-term"' /tmp/t.html
echo -n "含 xterm 样式: "; grep -c '\.xterm-screen' /tmp/t.html
echo "== 输出片段 =="
head -c 400 /tmp/t.html
echo
