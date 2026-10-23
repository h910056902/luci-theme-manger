#!/bin/sh
echo "== 开启转发（指向本机 8080 作为假 webhook） =="
uci set kpsmsfwd.main.enable='1'
uci set kpsmsfwd.main.url='http://192.168.66.1:8080/cgi-bin/luci'
uci set kpsmsfwd.main.interval='10'
uci commit kpsmsfwd
/etc/init.d/kpsmsfwd restart
sleep 3

echo "== 进程 =="
ps w | grep '[k]psmsfwd' | head -2

echo "== 日志 =="
cat /tmp/kpsmsfwd.log 2>/dev/null | tail -5

echo "== 已见记录数 =="
wc -l < /tmp/kpsmsfwd.seen 2>/dev/null || echo 0

echo "== 再等一个周期，确认没有崩溃 =="
sleep 12
ps w | grep -c '[k]psmsfwd'

echo "== 恢复默认：关闭 =="
uci set kpsmsfwd.main.enable='0'
uci set kpsmsfwd.main.url=''
uci commit kpsmsfwd
/etc/init.d/kpsmsfwd restart
sleep 1
ps w | grep -c '[k]psmsfwd'
echo DONE
