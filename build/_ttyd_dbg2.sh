#!/bin/sh
echo "== 直接跑二进制的命令 =="
ls -l /usr/bin/ttyd
ls -l /etc/ttyd/index.html 2>/dev/null

echo "== procd 启动 trace =="
sh -x /etc/init.d/ttyd8080 start 2>&1 | tail -25

echo "== 进程/端口 =="
ps w | grep '[/]usr/bin/ttyd' | head -3
netstat -lnt 2>/dev/null | grep 7681

echo "== logread =="
logread 2>/dev/null | tail -12

echo "== 再手工确认一次可用 =="
/usr/bin/ttyd -p 7681 -i br-lan -I /etc/ttyd/index.html /bin/sh >/tmp/t.log 2>&1 &
sleep 2
ps w | grep '[/]usr/bin/ttyd' | head -2
netstat -lnt 2>/dev/null | grep 7681
head -3 /tmp/t.log
