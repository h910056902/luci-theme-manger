#!/bin/sh
echo "===== parser.lua 里 <%+ 的编译逻辑 ====="
grep -n -B3 -A10 "include" /usr/lib/lua/luci/template/parser.lua 2>/dev/null | head -40
echo
echo "===== template.lua 的 Template:render ====="
sed -n '/function Template.render/,/^end/p' /usr/lib/lua/luci/template.lua 2>/dev/null | head -25
