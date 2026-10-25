#!/bin/sh
pkill -f '/usr/bin/ttyd' 2>/dev/null
sleep 1

echo "== init 脚本内容（关键行）=="
grep -nE 'procd_set_param|command|index|check-origin|--' /etc/init.d/ttyd | head -12

echo "== 手动试跑：最简 =="
nohup /usr/bin/ttyd -p 7681 -i br-lan /bin/sh >/tmp/ttyd1.log 2>&1 &
sleep 3
ps w | grep '[t]tyd' | head -2
netstat -lnt 2>/dev/null | grep 7681
echo "  log1:"; head -5 /tmp/ttyd1.log

echo "== 手动试跑：带 index 与 check-origin =="
pkill -f '/usr/bin/ttyd' 2>/dev/null; sleep 1
nohup /usr/bin/ttyd -p 7681 -i br-lan -W -O -I /etc/ttyd/index.html /bin/sh >/tmp/ttyd2.log 2>&1 &
sleep 3
ps w | grep '[t]tyd' | head -2
netstat -lnt 2>/dev/null | grep 7681
echo "  log2:"; head -8 /tmp/ttyd2.log

echo "== HTTP 测试 =="
curl -s -o /dev/null -m 6 -w "  7681: %{http_code}\n" http://192.168.66.1:7681/
