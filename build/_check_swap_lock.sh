#!/bin/sh
echo "== swap 状态 =="
free 2>/dev/null | sed -n '1,4p'
echo "-- swapon --"
swapon -s 2>/dev/null || cat /proc/swaps
echo "-- fstab --"
uci -q show fstab 2>/dev/null | head -20
echo "-- swap init --"
ls -l /etc/init.d/*swap* 2>/dev/null || echo "无 swap init 脚本"

echo "== 相关包 =="
opkg list-installed 2>/dev/null | grep -iE 'swap|simlock|hsimlock|unlock' || echo "无相关包"

echo "== LuCI 视图 =="
ls /usr/lib/lua/luci/view/ 2>/dev/null | grep -iE 'swap|lock|sim'
ls /usr/lib/lua/luci/view/nradio_adv/ 2>/dev/null | head -20

echo "== 控制器 =="
grep -rl -iE 'swap|simlock' /usr/lib/lua/luci/controller/ 2>/dev/null | head -10

echo "== ubus =="
ubus list 2>/dev/null | grep -iE 'swap|lock|sim' | head -10

echo "== SIM 锁状态（AT） =="
ubus call atsdcpe at_cmd '{"cmd":"AT+CLCK=\"PN\",2","wait":1500,"at_log_level":0,"block":1}' 2>&1 | tr -d '\r' | head -c 300
echo
ubus call atsdcpe at_cmd '{"cmd":"AT^SIMLOCK?","wait":1500,"at_log_level":0,"block":1}' 2>&1 | tr -d '\r' | head -c 300
echo
