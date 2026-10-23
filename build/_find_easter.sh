#!/bin/sh
echo "== 控制器中提到 openclash 的文件 =="
grep -rln openclash /usr/lib/lua/luci/controller/ 2>/dev/null

echo "== openclash 控制器的入口 =="
grep -n "entry(" /usr/lib/lua/luci/controller/openclash.lua 2>/dev/null | head -10

echo "== 出现 unlock / secret / hidden / easter 的控制器 =="
grep -rln "unlock\|secret\|hidden\|easter\|magic" /usr/lib/lua/luci/controller/ 2>/dev/null | head -10

echo "== 前端 JS 中的 unlock/secret =="
grep -rln "unlock\|easter\|secretClick\|clickCount\|tapCount" /www/luci-static/resources/ 2>/dev/null | head -10

echo "== 菜单相关 uci =="
uci -q show luci 2>/dev/null | head -12
echo "== openclash 配置开关 =="
uci -q show openclash 2>/dev/null | grep -E "enable|hide|menu" | head -8
