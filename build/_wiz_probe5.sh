#!/bin/sh
echo "== 1. 控制器 433 行上下文（openclash.sh 的参数是什么） =="
sed -n '420,445p' /usr/lib/lua/luci/controller/openclash.lua
echo
echo "== 2. openclash.sh sub_info_get 匹配逻辑 =="
sed -n '340,480p' /usr/share/openclash/openclash.sh | grep -n 'section\|name\|address\|\[ \]' | head -20
echo
echo "== 3. 重启目标服务存在性 =="
ls /etc/init.d/ | grep -E 'cpesel|wanchk|tcsd|openclash'
echo
echo "== 4. openclash 运行状态 =="
ps w | grep -E 'clash' | grep -v grep | head -4
echo
echo "== 5. 订阅日志样例（最后 12 行） =="
tail -12 /tmp/openclash.log 2>/dev/null
echo
echo "== 6. 寂寞卡/卡槽名称与 gval 解读 =="
uci -q get cpesel.sim.gval; uci -q get cpesel.sim.stype; uci -q get cpesel.sim.cur
uci show cpesel 2>/dev/null | grep -E '=iccid|\.name' | head -8
echo
echo "== 7. firewall/网络重载对 wizard 是否必要（wifi reload 而已） =="
ls /sbin/wifi
