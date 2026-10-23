#!/bin/sh
echo "== LuCI 里的 ttyd 视图 =="
ls -l /usr/lib/lua/luci/view/ttyd/ 2>/dev/null || echo "无 view/ttyd"
echo "== 控制器 =="
cat /usr/lib/lua/luci/controller/ttyd.lua 2>/dev/null | head -20 || echo "无 controller"
echo "== 引用 7681 的视图 =="
grep -rln '7681' /usr/lib/lua/luci/view/ /www/luci-static/resources/ 2>/dev/null | head -8
echo "== 任何 ttyd 相关 html =="
find / -xdev -iname '*ttyd*' -type f 2>/dev/null | grep -v proc | head -20
echo "== xterm 视图（厂商） =="
ls -l /usr/lib/lua/luci/view/xterm/ 2>/dev/null || echo "无 view/xterm"
echo "== 菜单中出现的中文终端字样 =="
grep -rn '终端\|Web SSH\|Terminal' /usr/lib/lua/luci/controller/ttyd.lua /usr/lib/lua/luci/view/ttyd/*.htm 2>/dev/null | head -10
