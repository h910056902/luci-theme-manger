#!/bin/sh
echo "== 1. 报错位置 =="
sed -n '118,128p' /usr/lib/lua/luci/controller/openclash.lua 2>/dev/null

echo "== 2. luci.openclash 模块是否存在 =="
ls -l /usr/lib/lua/luci/openclash.lua 2>/dev/null || echo "  缺失 /usr/lib/lua/luci/openclash.lua"
find /usr/lib/lua /usr/share/lua -maxdepth 3 -name 'openclash*' 2>/dev/null | head -10

echo "== 3. 恢复包里是否有该模块 =="
mkdir -p /tmp/ocm && cd /tmp/ocm || exit 1
tar -xzf /overlay/kp-restore-20261025-194209.ipk data.tar.gz 2>/dev/null
tar -tzf data.tar.gz 2>/dev/null | grep -E 'lua/luci/(openclash|model/openclash)' | head -10
echo "  --- 全部 openclash 的 lua 条目 ---"
tar -tzf data.tar.gz 2>/dev/null | grep 'openclash.*\.lua$' | head -15
rm -rf /tmp/ocm

echo "== 4. 80 端口 LuCI 类型 =="
opkg list-installed 2>/dev/null | grep -E 'luci-compat|luci-base|luci-lua' | head -5
ls /usr/share/ucode/luci/ 2>/dev/null | head -5
ls /usr/share/luci/menu.d/ 2>/dev/null | grep -i openclash || echo "  menu.d 无 openclash"

echo "== 5. 8080 面板当前是否可访问 =="
curl -s -o /dev/null -m 8 -w "  panel=%{http_code}\n" http://192.168.66.1:8080/cgi-bin/luci
