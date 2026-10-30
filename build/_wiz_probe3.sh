#!/bin/sh
echo "== 1. 定位 cpesel / kpcpe-ctl =="
find /usr/bin /usr/sbin /bin /sbin -name '*cpesel*' -o -name 'kpcpe*' 2>/dev/null
echo
echo "== 2. cpesel.sh 内容 =="
for f in $(find /usr/bin /usr/sbin /bin /sbin -name '*cpesel*' 2>/dev/null); do echo "--- $f"; cat "$f"; done
echo
echo "== 3. cpecfg uci 结构 =="
uci show cpecfg 2>/dev/null | head -50
echo
echo "== 4. sync_cpecfg.sh 头部 =="
head -60 /usr/sbin/sync_cpecfg.sh 2>/dev/null
echo
echo "== 5. OpenClash LuCI 如何触发订阅更新 =="
grep -n "openclash.sh" /usr/lib/lua/luci/controller/openclash.lua 2>/dev/null | head -10
echo
echo "== 6. openclash.sh 参数分支 =="
grep -n '\$1\|while\|case\|only_download\|restart=1' /usr/share/openclash/openclash.sh 2>/dev/null | head -25
echo
echo "== 7. ubus atsd 对象 =="
ubus list 2>/dev/null | grep -i atsd
