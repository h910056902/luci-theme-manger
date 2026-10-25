#!/bin/sh
echo "== 安装 =="
tr -d '\r' < /tmp/_up_ocspeed        > /usr/bin/ocspeed
tr -d '\r' < /tmp/_up_ocspeed_init   > /etc/init.d/ocspeed
chmod 755 /usr/bin/ocspeed /etc/init.d/ocspeed

lua -e "assert(loadfile('/usr/bin/ocspeed'))" && echo "  ocspeed 语法 OK"
sh -n /etc/init.d/ocspeed && echo "  init 语法 OK"

echo "== 配置 =="
uci show ocspeed 2>/dev/null | head -6

echo "== 清零日志并启动 =="
: > /tmp/ocspeed.log
: > /tmp/ocspeed.state
/etc/init.d/ocspeed enable 2>/dev/null
/etc/init.d/ocspeed restart >/dev/null 2>&1
sleep 12

echo "== 进程 =="
ps w | grep '[o]cspeed' | head -3
echo "== 状态 =="
cat /tmp/ocspeed.state 2>/dev/null
echo "== 日志 =="
tail -10 /tmp/ocspeed.log 2>/dev/null
