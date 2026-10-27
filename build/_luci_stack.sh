#!/bin/sh
echo "== 1. LuCI 实现形态 =="
ls -d /usr/lib/lua/luci 2>/dev/null && echo "  有 Lua 版 LuCI"
ls -d /usr/share/ucode/luci 2>/dev/null && echo "  有 ucode 版 LuCI"
ls /www/luci-static/resources/view 2>/dev/null | head -5
echo -n "  luci-compat: "; apk info -e luci-compat 2>/dev/null || opkg list-installed 2>/dev/null | grep -c '^luci-compat' 
echo -n "  luci-base:   "; apk info -e luci-base 2>/dev/null || opkg list-installed 2>/dev/null | grep -c '^luci-base'

echo "== 2. 菜单定义位置 =="
ls /usr/share/luci/menu.d/*.json 2>/dev/null | head -8
echo "  菜单 JSON 总数: $(ls /usr/share/luci/menu.d/*.json 2>/dev/null | wc -l)"

echo "== 3. Lua controller 目录 =="
ls /usr/lib/lua/luci/controller/ 2>/dev/null | head -10
echo "  控制器数: $(ls /usr/lib/lua/luci/controller/*.lua 2>/dev/null | wc -l)"

echo "== 4. fw_printenv 为何为空 =="
cat /etc/fw_env.config 2>/dev/null || echo "  无 /etc/fw_env.config"
fw_printenv 2>&1 | head -4

echo "== 5. 恢复相关命令 =="
for c in mtd nanddump nandwrite fw_setenv sysupgrade firstboot; do
	printf "  %-12s %s\n" "$c" "$(command -v $c 2>/dev/null || echo -)"
done
