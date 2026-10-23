#!/bin/sh
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_term.htm
echo "== 高度相关 =="
grep -o 'height:calc(100vh[^;]*' "$F" | head -3
grep -o '#terminal-container{[^}]*}' "$F" | head -3
echo "== 80vh 出现处 =="
grep -o '.\{0,40\}height:80vh.\{0,40\}' "$F" | head -3
echo "== 模板标签配平 =="
echo -n "<% 数量: "; grep -o '<%' "$F" | wc -l
echo -n "%> 数量: "; grep -o '%>' "$F" | wc -l
echo "== 关键片段 =="
grep -o 'local is_running = 1' "$F" | head -1
grep -o 'kp_term_css' "$F" | head -2
grep -o 'new WebSocket([^)]*)' "$F" | head -1 | cut -c1-120
