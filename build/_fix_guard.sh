#!/bin/sh
# KP-FIX-GUARD v3: 修正"保留谁"的选择逻辑
# 旧逻辑保留最小 PID —— 但 PID 会回绕，会把真实例杀掉、留下野实例（实测踩到）
# 新逻辑: 优先保留锁文件指向的 PID（真实例持有者）；锁失效时按 /proc/PID/stat
#         的 starttime 取最早启动的那个
LOG=/tmp/kp_fixguard.log
: > $LOG
say(){ echo "$@" >> $LOG; }

cat > /usr/bin/kp-oc-wd-guard.sh <<'GUARD'
#!/bin/sh
# KP-OC-WD-GUARD v3: 保证 openclash_watchdog.sh 恒为 1 份
# 背景: watchdog 是常驻守护(while true + sleep 60)；OpenClash 的 openclash.sh 每次执行
#       都会 -> add_cron -> start_watchdog 再注册一个实例，老实例变孤儿继续跑，
#       新实例又触发同一链路 -> 指数增殖（曾达 2201 实例 / load 447）。
#       源头已修（init.d 幂等 + 脚本 pidfile 锁），本守护防厂商更新覆盖后复发。
#
# 保留策略（重要）: 优先保留 pidfile 里登记的那个实例；pidfile 失效时按
#                   /proc/PID/stat 的 starttime 取最早启动者。
#                   ⚠ 不能用"最小 PID"——PID 会回绕，会误杀真实例。
WD=/usr/share/openclash/openclash_watchdog.sh
LOCK=/var/run/openclash_watchdog.pid
LOG=/tmp/kp-oc-wd-guard.log
PAT='openclash_watchdog.sh'

cnt=$(pgrep -f "$PAT" 2>/dev/null | wc -l)
if [ "$cnt" -eq 0 ]; then
  # 只在 OpenClash 核心在跑时才补
  if pgrep -f '/etc/openclash/clash' >/dev/null 2>&1; then
    rm -f "$LOCK"
    nohup sh "$WD" >/dev/null 2>&1 &
    echo "$(date '+%F %T') 补拉 watchdog" >> "$LOG"
  fi
  exit 0
fi

[ "$cnt" -le 1 ] && exit 0

keep=""
lockpid=$(cat "$LOCK" 2>/dev/null)
if [ -n "$lockpid" ] && [ -d "/proc/$lockpid" ]; then
  keep=$lockpid
else
  best=""; bestst=""
  for p in $(pgrep -f "$PAT" 2>/dev/null); do
    st=$(awk '{print $22}' "/proc/$p/stat" 2>/dev/null)
    [ -z "$st" ] && continue
    if [ -z "$best" ] || [ "$st" -lt "$bestst" ]; then best=$p; bestst=$st; fi
  done
  keep=$best
  [ -n "$keep" ] && echo "$keep" > "$LOCK"
fi

[ -z "$keep" ] && exit 0
for p in $(pgrep -f "$PAT" 2>/dev/null); do
  [ "$p" = "$keep" ] || kill -9 "$p" 2>/dev/null
done
echo "$(date '+%F %T') 收敛 $cnt -> 1 (keep $keep)" >> "$LOG"
GUARD
chmod +x /usr/bin/kp-oc-wd-guard.sh
say "守护脚本已更新，语法: $(sh -n /usr/bin/kp-oc-wd-guard.sh 2>&1 && echo OK)"

say ""
say "=== 修复当前错乱状态：杀掉残留野实例，重启真实例 ==="
for p in $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null); do
  kill -9 "$p" 2>/dev/null
  say "  杀掉 $p"
done
sleep 1
rm -f /var/run/openclash_watchdog.pid /tmp/fake_openclash_watchdog.sh
nohup sh /usr/share/openclash/openclash_watchdog.sh >/dev/null 2>&1 &
sleep 3
say "  新实例: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | tr '\n' ' ')"
say "  锁文件: $(cat /var/run/openclash_watchdog.pid 2>/dev/null)"

say ""
say "=== 重测守护：造假实例应杀假、留真 ==="
printf '#!/bin/sh\nwhile :; do sleep 5; done\n' > /tmp/fake_openclash_watchdog.sh
chmod +x /tmp/fake_openclash_watchdog.sh
nohup /tmp/fake_openclash_watchdog.sh >/dev/null 2>&1 &
sleep 2
say "  造实例后: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | tr '\n' ' ')"
/usr/bin/kp-oc-wd-guard.sh
sleep 1
real=$(cat /var/run/openclash_watchdog.pid 2>/dev/null)
say "  收敛后:   $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | tr '\n' ' ')"
say "  真实例(PID $real) 是否存活: $([ -d /proc/$real ] && echo 是 || echo 否)"
say "  守护日志: $(tail -1 /tmp/kp-oc-wd-guard.log 2>/dev/null)"
rm -f /tmp/fake_openclash_watchdog.sh

say ""
say "=== 最终状态 ==="
say "  watchdog: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)  总进程: $(ps w | wc -l)"
say -n "  loadavg: "; cat /proc/loadavg >> $LOG
cat $LOG
