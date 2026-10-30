#!/bin/sh
echo "== 1. 主题与资源路径 =="
uci -q get luci.main.mediaurlbase
uci -q get luci.themes.Argon 2>/dev/null
ls /www/luci-static/argon/css/ 2>/dev/null | head -10
echo
echo "== 2. ocspeed.htm 头部与 token 定义 =="
head -60 /usr/lib/lua/luci/view/ocspeed.htm
echo
echo "== 3. 暗色机制（argon） =="
grep -o 'body\.dark\|html\.dark\|\[data-theme[^]]*\]\|\.dark-mode\|prefers-color-scheme[^{]*' /www/luci-static/argon/css/*.css 2>/dev/null | sort | uniq -c | sort -rn | head -10
echo
echo "== 4. argon 主色变量 =="
grep -o -- '--[a-z0-9-]*:[^;]*' /www/luci-static/argon/css/*.css 2>/dev/null | head -40
echo
echo "== 5. ocspeed.htm 里用到的 token（前 30） =="
grep -o -- 'var(--[a-z0-9-]*)' /usr/lib/lua/luci/view/ocspeed.htm | sort | uniq -c | sort -rn | head -30
echo
echo "== 6. nodetest.htm 是否也带同套样式 =="
grep -c 'data-darkmode\|--bg-white' /usr/lib/lua/luci/view/nodetest.htm
