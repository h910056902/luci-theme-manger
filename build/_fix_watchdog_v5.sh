#!/bin/sh
# KP-FIX-WATCHDOG-LEAK v5：用 pgrep+kill（本机 pkill 不可用），procd 用正确函数库
LOG=/tmp/kp_fix5.log
: > $LOG
say(){ echo "$@" >> $LOG; }

say "=== [1] 校验补丁完整性 ==="
grep -c 'KP-OC-WD-LOCK' /usr/share/openclash/openclash_watchdog.sh
say "锁补丁: $(grep -c 'KP-OC-WD-LOCK' /usr/share/openclash/openclash_watchdog.sh)"
say "幂等补丁: $(grep -c 'procd_running openclash-watchdog' /etc/init.d/openclash)"
say "脚本头部:"
head -10 /usr/share/openclash/openclash_watchdog.sh | sed 's/^/  /' >> $LOG
say "语法检查: $(sh -n /usr/share/openclash/openclash_watchdog.sh 2>&1 && echo OK)"

say ""
say "=== [2] 分批 kill -9 全部 watchdog ==="
round=0
while [ $round -lt 10 ]; do
  n=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)
  say "  round $round 剩余 $n"
  [ "$n" -eq 0 ] && break
  pgrep -f 'openclash_watchdog.sh' 2>/dev/null | head -100 | while read -r p; do
    kill -9 "$p" 2>/dev/null
  done
  sleep 1
  round=$((round+1))
done
say "  清理后: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"

say ""
say "=== [3] 用 procd 注册唯一实例（正确函数库 /lib/functions/procd.sh）==="
rm -f /var/run/openclash_watchdog.pid
ubus call service delete '{"name":"openclash","instance":"openclash-watchdog"}' 2>&1 | head -1 >> $LOG
sleep 1
sh -c '. /lib/functions/procd.sh; procd_open_instance "openclash-watchdog"; procd_set_param command "/usr/share/openclash/openclash_watchdog.sh"; procd_close_instance' 2>&1 | head -3 >> $LOG
sleep 5
say "  实例数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
say "  锁文件: $(cat /var/run/openclash_watchdog.pid 2>/dev/null || echo 无)"

say ""
say "=== [4] 稳定性观察 25 秒（是否还在增殖）==="
sleep 25
say "  25 秒后实例数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
say "  总进程: $(ps w | wc -l)"
say -n "  loadavg: "; cat /proc/loadavg >> $LOG
free -m | head -2 >> $LOG
say "  clash: $(ps w | grep -c '[c]lash -d')"
cat $LOG
