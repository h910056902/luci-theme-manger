#!/bin/sh
echo "== 停掉手工进程与 stock 服务 =="
pkill -f '/usr/bin/ttyd' 2>/dev/null
/etc/init.d/ttyd stop >/dev/null 2>&1
/etc/init.d/ttyd disable >/dev/null 2>&1
sleep 1

echo "== 安装 ttyd8080 =="
tr -d '\r' < /tmp/_up_ttyd8080 > /etc/init.d/ttyd8080
chmod 755 /etc/init.d/ttyd8080
sh -n /etc/init.d/ttyd8080 && echo "  语法 OK"
ls -l /etc/init.d/ttyd8080

echo "== 启用并启动 =="
/etc/init.d/ttyd8080 enable 2>/dev/null
/etc/init.d/ttyd8080 start 2>&1 | head -5
sleep 3
ps w | grep '[t]tyd' | head -2
netstat -lnt 2>/dev/null | grep 7681
curl -s -o /dev/null -m 8 -w "  http=%{http_code}\n" http://192.168.66.1:7681/

echo "== 跨源握手指令准备（无 -O 即允许）=="
grep -c 'check_origin' /etc/init.d/ttyd8080 2>/dev/null || true
echo "== 开机自启 =="
ls -l /etc/rc.d/ | grep ttyd
