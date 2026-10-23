#!/bin/sh
echo "== openclash.lua 前 14 行 =="
sed -n '1,14p' /usr/lib/lua/luci/controller/openclash.lua

echo "== app.lua 里的 unlock/secret/hidden 行 =="
grep -n "unlock\|secret\|hidden\|easter\|magic" /usr/lib/lua/luci/controller/nradio/app.lua | head -25

echo "== 这些关键字附近的上下文 =="
grep -n -A3 -B3 "unlock" /usr/lib/lua/luci/controller/nradio/app.lua | head -40
