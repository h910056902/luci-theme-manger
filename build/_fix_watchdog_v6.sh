#!/bin/sh
# KP-FIX-WATCHDOG-LEAK v6：补自愈守护（保证恒为 1 份：多了杀少，少了补上）
LOG=/tmp/kp_fix6.log
: > $LOG
say(){ echo "$@" >> $LOG; }

say "=== [1] 升级兜底守护：多了收敛、少了拉起 ==="
cat > /usr/bin/kp-oc-wd-guard.sh <<'GUARD'
#!/bin/sh
# KP-OC-WD-GUARD v2: 保证 openclash_watchdog.sh 恒为 1 份
# - 多于 1 份：保留最早启动的那份，其余杀掉
# - 0 份：拉起一份（脚本自带 pidfile 单实例锁）
# 背景：watchdog 是常驻守护（while true + sleep 60）；OpenClash 的 openclash.sh
#       每次执行都会 -> add_cron -> start_watchdog 再注册一个实例，老实例变孤儿，
#       且新实例又会触发同一链路，曾导致 2 天累积 2000+ 份、load 447。
#       源头已修（init.d 幂等 + 脚本 pidfile 锁），本守护防厂商更新覆盖后复发。
WD=/usr/share/openclash/openclash_watchdog.sh
LOG=/tmp/kp-oc-wd-guard.log
cnt=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)

if [ "$cnt" -gt 1 ]; then
  pids=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | sort -n)
  keep=$(echo "$pids" | head -1)
  for p in $pids; do
    [ "$p" = "$keep" ] || kill -9 "$p" 2>/dev/null
  done
  echo "$(date '+%F %T') 收敛 $cnt -> 1 (keep $keep)" >> $LOG
elif [ "$cnt" -eq 0 ]; then
  # 只在 OpenClash 核心在跑时才补 watchdog
  if pgrep -f '/etc/openclash/clash' >/dev/null 2>&1; then
    rm -f /var/run/openclash_watchdog.pid
    setsid "$WD" >/dev/null 2>&1 &
    echo "$(date '+%F %T') 补拉 watchdog (clash 在跑但 watchdog 缺失)" >> $LOG
  fi
fi
GUARD
chmod +x /usr/bin/kp-oc-wd-guard.sh
say "  守护脚本已更新"

say ""
say "=== [2] 立即拉起一份 watchdog ==="
rm -f /var/run/openclash_watchdog.pid
setsid /usr/share/openclash/openclash_watchdog.sh >/dev/null 2>&1 &
sleep 5
say "  实例数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
say "  锁文件 PID: $(cat /var/run/openclash_watchdog.pid 2>/dev/null || echo 无)"

say ""
say "=== [3] 再试一次 procd 注册（通过 init.d 幂等函数，走正规上下文）==="
# 用 openclash 的 stop/start 只重建 watchdog 不现实；这里验证幂等补丁是否会让
# /etc/init.d/openclash 的 start_watchdog 在已有实例时直接返回（不新增）
sh /etc/init.d/openclash start >/dev/null 2>&1
sleep 3
say "  init start 后实例数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)  (应仍为 1，证明幂等生效)"

say ""
say "=== [4] 稳定性观察 30 秒 ==="
sleep 30
say "  30 秒后实例数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
say "  总进程: $(ps w | wc -l)"
say -n "  loadavg: "; cat /proc/loadavg >> $LOG
free -m | head -2 >> $LOG
say "  clash: $(ps w | grep -c '[c]lash -d')"
say "  OpenClash 代理连通性:"
curl -s -m 8 -o /dev/null -w "    clash api http_code=%{http_code}\n" http://127.0.0.1:9090/version 2>&1 >> $LOG
cat $LOG
