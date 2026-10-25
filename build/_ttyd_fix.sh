#!/bin/sh
pkill -f '/usr/bin/ttyd' 2>/dev/null
sleep 1

echo "== ttyd origin 相关参数 =="
/usr/bin/ttyd --help 2>&1 | grep -iE 'origin|writable|index' | head -6

echo "== init 脚本 trace =="
sh -x /etc/init.d/ttyd start 2>&1 | tail -18

echo "== 结果 =="
ps w | grep '[t]tyd' | head -2
netstat -lnt 2>/dev/null | grep 7681
