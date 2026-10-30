#!/bin/sh
echo "== 1. cpesel.sh 全文 =="
cat /usr/sbin/cpesel.sh 2>/dev/null
echo
echo "== 2. kpcpe-ctl 类型与用法 =="
file /usr/sbin/kpcpe-ctl 2>/dev/null || ls -la /usr/sbin/kpcpe-ctl
/usr/sbin/kpcpe-ctl 2>&1 | head -15
echo
echo "== 3. nrswitch 无参运行（看用法） =="
/usr/sbin/nrswitch 2>&1 | head -15
echo
echo "== 4. openclash.sh 头部用法 =="
head -50 /usr/share/openclash/openclash.sh 2>/dev/null
echo
echo "== 5. OpenClash LuCI 里 config_subscribe 的更新入口 =="
grep -n "config_subscribe" /usr/lib/lua/luci/controller/openclash.lua 2>/dev/null | head -10
grep -rn "config_subscribe" /usr/share/openclash/openclash.sh 2>/dev/null | head -10
echo
echo "== 6. 当前线路状态 =="
ubus call infocd runtime 2>/dev/null | grep -E '"name"|"gateway_if"|"status"' | head -10
ip route show default | head -5
