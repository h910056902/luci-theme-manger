#!/bin/sh
# KP-FIX-WATCHDOG-LEAK v3（彻底版）
# 根因链: openclash_watchdog.sh 是常驻守护(循环尾 sleep 60)
#   watchdog:401 -> /usr/share/openclash/openclash.sh -> add_cron() -> start_watchdog()
#   -> procd 注册同名实例 -> procd 又拉起一份新 watchdog，旧的那份变孤儿继续跑
#   -> 新实例再进入循环 -> 指数增殖（实测 2 天 386 份，当天涨到 2000+ 份 / 3800+ 进程）
# 修复三层:
#   A) 源头幂等: init.d/openclash 的 start_watchdog 先判断实例是否已在跑
#   B) 脚本单实例锁: pidfile 检查，重复拉起直接退出（自愈：僵死 pidfile 自动接管）
#   C) 兜底守护: kp-oc-wd-guard.sh 每 5 分钟收敛到 1 份（防厂商更新覆盖 A/B 后复发）
LOG=/tmp/kp_fix3.log
: > $LOG
say(){ echo "$@" >> $LOG; }

say "=== [0] 停掉上一版卡住的修复脚本 ==="
for p in $(ls /proc 2>/dev/null | grep -E '^[0-9]+$'); do
  c=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)
  case "$c" in *_fixwd.sh*|*_fix_watchdog_leak.sh*|*_fix2.sh*) kill -9 "$p" 2>/dev/null;; esac
done

say "=== [1] 注销 procd 里的 openclash-watchdog 实例 ==="
ubus call service delete '{"name":"openclash","instance":"openclash-watchdog"}' >> $LOG 2>&1

say "=== [2] 清场：循环杀光所有 watchdog 进程 ==="
i=0
while [ $i -lt 8 ]; do
  c=$(ps w | grep -c '[o]penclash_watchdog.sh')
  say "  round $i  实例数=$c"
  [ "$c" -eq 0 ] && break
  pkill -9 -f 'openclash_watchdog.sh' 2>/dev/null
  sleep 2
  i=$((i+1))
done
# 收掉无主的 sleep 60
for p in $(ls /proc 2>/dev/null | grep -E '^[0-9]+$'); do
  c=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null | sed 's/ *$//')
  [ "$c" = "sleep 60" ] && kill -9 "$p" 2>/dev/null
done
say "  清理后实例数: $(ps w | grep -c '[o]penclash_watchdog.sh')  总进程: $(ps w | wc -l)"

say ""
say "=== [3] 修 A: init.d/openclash 的 start_watchdog 改成幂等 ==="
cp /etc/init.d/openclash /etc/init.d/openclash.kp.bak
awk '
{
  if ($0 ~ /procd_open_instance "openclash-watchdog"/ && !ins) {
    print "\tprocd_running openclash-watchdog >/dev/null && return 0";
    ins = 1
  }
  print
}' /etc/init.d/openclash > /tmp/openclash.init.new 2>/dev/null
if [ -s /tmp/openclash.init.new ]; then
  mv /tmp/openclash.init.new /etc/init.d/openclash
  chmod +x /etc/init.d/openclash
  say "  已插入幂等判断:"
  sed -n '/^start_watchdog()/,/^}/p' /etc/init.d/openclash | sed 's/^/    /' >> $LOG
else
  say "  !! awk 失败，未改动"
fi

say ""
say "=== [4] 修 B: watchdog 脚本加单实例锁（pidfile 自愈）==="
WD=/usr/share/openclash/openclash_watchdog.sh
cp "$WD" "$WD.kp.bak"
if ! grep -q 'KP-OC-WD-LOCK' "$WD"; then
  awk '
BEGIN { added = 0 }
NR == 1 {
  print "#!/bin/sh"
  print "# KP-OC-WD-LOCK: 单实例锁（防 procd/cron 重复拉起导致指数增殖）"
  print "# 僵死 pidfile 会自动被接管（/proc/<pid> 不存在即视为失效）"
  print "KP_WD_LOCK=/var/run/openclash_watchdog.pid"
  print "if [ -f \"$KP_WD_LOCK\" ]; then"
  print "  _old=$(cat \"$KP_WD_LOCK\" 2>/dev/null)"
  print "  [ -n \"$_old\" ] && [ -d \"/proc/$_old\" ] && exit 0"
  print "fi"
  print "echo $$ > \"$KP_WD_LOCK\""
  added = 1
  next
}
{ print }
' "$WD" > /tmp/wd.new 2>/dev/null
  if [ -s /tmp/wd.new ]; then
    mv /tmp/wd.new "$WD"
    chmod +x "$WD"
    say "  已注入单实例锁，脚本头部:"
    head -12 "$WD" | sed 's/^/    /' >> $LOG
  else
    say "  !! awk 失败，未改动"
  fi
else
  say "  已存在锁，跳过"
fi

say ""
say "=== [5] 修 C: 兜底守护（每 5 分钟收敛到 1 份）==="
cat > /usr/bin/kp-oc-wd-guard.sh <<'GUARD'
#!/bin/sh
# KP-OC-WD-GUARD: 保证 openclash_watchdog.sh 全机只有一份
# 厂商更新覆盖 openclash_watchdog.sh / init.d/openclash 时，靠它兜底防复发
cnt=$(ps w | grep -c '[o]penclash_watchdog.sh')
[ "$cnt" -le 1 ] && exit 0
pids=$(ps w | grep '[o]penclash_watchdog.sh' | awk '{print $1}' | sort -n)
keep=$(echo "$pids" | head -1)
for p in $pids; do
  [ "$p" = "$keep" ] || kill -9 "$p" 2>/dev/null
done
echo "$(date '+%F %T') 收敛 watchdog: $cnt -> 1 (keep $keep)" >> /tmp/kp-oc-wd-guard.log
GUARD
chmod +x /usr/bin/kp-oc-wd-guard.sh
grep -q 'kp-oc-wd-guard' /etc/crontabs/root || echo '*/5 * * * * /usr/bin/kp-oc-wd-guard.sh #kp-oc-wd-guard' >> /etc/crontabs/root
say "  crontab:"; cat /etc/crontabs/root | sed 's/^/    /' >> $LOG

say ""
say "=== [6] 通过 procd 拉起唯一实例 ==="
cat > /tmp/_kp_wd_register.sh <<'EOF'
#!/bin/sh
. /lib/functions.sh
procd_open_instance "openclash-watchdog"
procd_set_param command "/usr/share/openclash/openclash_watchdog.sh"
procd_close_instance
EOF
sh /tmp/_kp_wd_register.sh 2>&1 | head -3 >> $LOG
sleep 5
say "  实例数: $(ps w | grep -c '[o]penclash_watchdog.sh')"

say ""
say "=== [7] 结果 ==="
say "总进程数: $(ps w | wc -l)"
say -n "loadavg: "; cat /proc/loadavg >> $LOG
free -m | head -2 >> $LOG
say "clash 进程:"; ps w | grep '[c]lash -d' | head -2 >> $LOG
cat $LOG
