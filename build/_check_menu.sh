#!/bin/sh
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":1800}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
echo "SID=${SID:0:8}..."
echo "== 会话目录 =="
ls -d /tmp/luci-sessions 2>/dev/null || echo "无 /tmp/luci-sessions"
ls /tmp/luci-sessions 2>/dev/null | head -3

# 尝试写入文件会话（LuCI 21.02 的 luci.sauth 用 key=value 行）
if [ -d /tmp/luci-sessions ]; then
    printf 'user=root\ntoken=%s\n' "$SID" > "/tmp/luci-sessions/$SID"
    chmod 600 "/tmp/luci-sessions/$SID"
    echo "已写入会话文件"
fi

echo "== 抓取页面里的侧栏菜单 =="
curl -s -m 20 -H "Cookie: sysauth=$SID" \
    "http://192.168.66.1:8080/cgi-bin/luci/admin/status/overview" -o /tmp/menu.html

echo -n "页面大小: "; wc -c < /tmp/menu.html
echo -n "是否登录页: "; grep -c 'luci_password' /tmp/menu.html

echo "== 一级菜单 =="
grep -o 'class="menu"[^>]*>[^<]*' /tmp/menu.html | sed 's/.*>//' | head -20
echo "== 状态子菜单 =="
sed -n '/slide-menu/,/<\/ul>/p' /tmp/menu.html | grep -o '<a[^>]*>[^<]*</a>' | sed 's/<[^>]*>//g' | head -25
