#!/bin/sh
echo "== init 脚本 =="
ls -l /etc/init.d/ttyd 2>/dev/null
ls -l /etc/rc.d/ | grep ttyd || echo "  未 enable"

echo "== 配置 =="
uci show ttyd 2>/dev/null
cat /etc/config/ttyd 2>/dev/null | head -20

echo "== 手动启动 =="
/etc/init.d/ttyd stop >/dev/null 2>&1
/etc/init.d/ttyd start 2>&1 | head -10
sleep 3
ps w | grep '[t]tyd' | head -3
netstat -lnt 2>/dev/null | grep 7681

echo "== 前台试跑（3 秒）=="
timeout 3 /usr/bin/ttyd -p 7681 -i br-lan -W -O 0 /bin/sh 2>&1 | head -6
echo "  退出码: $?"

echo "== 日志 =="
logread 2>/dev/null | grep -i ttyd | tail -6

echo "== login 是否存在 =="
ls -l /bin/login /sbin/login 2>/dev/null || echo "  无 login"
