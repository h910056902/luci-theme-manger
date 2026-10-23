#!/bin/sh
echo "== view 文件 =="
ls -l /usr/lib/lua/luci/view/nradio_hsimlock/ 2>/dev/null
echo "== controller 关键行 =="
grep -nE 'entry\(|template|call\(' /usr/lib/lua/luci/controller/nradio/hsimlock.lua 2>/dev/null | head -15
echo "== controller 前 40 行 =="
sed -n '1,40p' /usr/lib/lua/luci/controller/nradio/hsimlock.lua 2>/dev/null
echo "== 该模块用到的 AT =="
grep -ohE 'AT[+^][A-Z0-9]+' /usr/lib/lua/luci/view/nradio_hsimlock/*.htm 2>/dev/null | sort -u | head -20
