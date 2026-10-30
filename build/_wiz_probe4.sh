#!/bin/sh
echo "== 1. cpesel 守护进程运行参数（关键：-c 当前卡号 -M 模式） =="
ps w 2>/dev/null | grep -E 'cpesel|kpcped' | grep -v grep
echo
echo "== 2. gCellularRule 指向哪个接口 =="
grep -n "gCellularRule=" /usr/bin/cpesel.sh | head -5
echo
echo "== 3. kpcpe-ctl 是脚本还是二进制 =="
head -c 80 /usr/bin/kpcpe-ctl 2>/dev/null | od -c | head -3
echo
echo "== 4. 厂商控制器目录 =="
ls /usr/lib/lua/luci/controller/nradio/ /usr/lib/lua/luci/controller/nradio_adv/ 2>/dev/null
echo
echo "== 5. 厂商控制器里的 SIM 切换线索 =="
grep -rn "cpesel\|switch_sim\|sim_switch\|simno\|cpesim" /usr/lib/lua/luci/controller/nradio/ /usr/lib/lua/luci/controller/nradio_adv/ 2>/dev/null | grep -v Binary | head -20
echo
echo "== 6. network 里 cpe 接口定义 =="
uci show network 2>/dev/null | grep -E "cpe" | head -25
echo
echo "== 7. openclash.sh 是否需要 bash（bash 在不在） =="
which bash
echo
echo "== 8. openclash 当前运行状态 =="
pgrep -c clash 2>/dev/null; uci -q get openclash.config.config_path
