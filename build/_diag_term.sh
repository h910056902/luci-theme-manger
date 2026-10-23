#!/bin/sh
# 诊断：终端页为什么没变化
D=/overlay/nradio-apps/openwrt-luci-8080
F=$D/usr/lib/lua/luci/view/admin_status/nradio_term.htm
SRC=/usr/lib/lua/luci/view/ttyd/overview.htm

echo "== 1. 文件是否是新版 =="
ls -l "$F"
echo -n "行数: "; wc -l < "$F"
echo -n "kpt-term 容器: "; grep -c 'id="kpt-term"' "$F"
echo -n "旧版 iframe 残留: "; grep -c 'kp-frame' "$F"

echo "== 2. xterm 样式是否存在（关键） =="
echo -n "参考页 CSS 行数 3-5: "; sed -n '3,5p' "$SRC" | wc -c
echo -n "本页是否含 .xterm 规则: "; grep -c '\.xterm' "$F"

echo "== 3. 模板能否编译 =="
lua -e '
local ok, err = pcall(function()
  local t = require "luci.template"
  t.render_string("<%= 1+1 %>")
end)
print(ok and "render_string OK" or ("ERR: " .. tostring(err)))
' 2>&1 | head -3

echo "== 4. 页面 HTTP 状态 =="
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":600}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
curl -s -o /tmp/term.html -w "code=%{http_code} size=%{size_download}\n" -m 10 \
	-H "Cookie: sysauth=$SID" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/terminal"
echo -n "响应是否登录页: "; grep -c 'luci_password' /tmp/term.html
echo -n "响应是否含 kpt: "; grep -c 'kpt-term' /tmp/term.html

echo "== 5. 菜单节点 =="
lua -e '
local s=io.open("/overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci"):read("*a")
print("terminal 节点:", (s:find("status.nodes.terminal") and "有") or "无")
print("白名单 nradio_term:", (s:find("admin_status/nradio_term.htm") and "有") or "无")
'
echo DONE
