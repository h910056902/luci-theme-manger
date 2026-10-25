#!/bin/sh
echo "== controller/kaiplus.lua =="
cat /usr/lib/lua/luci/controller/kaiplus.lua 2>/dev/null

echo "== view =="
ls -l /usr/lib/lua/luci/view/kaiplus/ 2>/dev/null
head -c 400 /usr/lib/lua/luci/view/kaiplus/kaiplus_status.htm 2>/dev/null
echo

echo "== 是否有 model / cbi =="
ls -l /usr/lib/lua/luci/model/cbi/kaiplus* 2>/dev/null
find /usr/lib/lua/luci/model -iname '*kaiplus*' 2>/dev/null | head -5

echo "== 加载测试 =="
lua -e 'local ok,err = pcall(require, "luci.controller.kaiplus"); print(ok, err)' 2>&1 | head -3

echo "== 菜单缓存里有没有 kaiplus =="
ls /tmp/luci-indexcache* 2>/dev/null
grep -c kaiplus /tmp/luci-indexcache* 2>/dev/null | head -3
