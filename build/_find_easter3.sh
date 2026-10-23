#!/bin/sh
echo "== /www 里提到 openclash 的文件 =="
grep -rln "openclash" /www 2>/dev/null | head -12

echo "== 计数类关键字 =="
grep -rln "click_times\|clickTimes\|clickCount\|tapCount\|easter\|unlock_plugin\|secret_tap" /www /usr/lib/lua 2>/dev/null | head -12

echo "== ocspeed 控制器 =="
grep -n "openclash\|entry(\|unlock" /usr/lib/lua/luci/controller/ocspeed.lua 2>/dev/null | head -20

echo "== appcenter 里的 openclash 行 =="
grep -n "openclash" /usr/lib/lua/luci/controller/nradio_adv/appcenter.lua 2>/dev/null | head -10
