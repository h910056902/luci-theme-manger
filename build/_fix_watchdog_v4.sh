#!/bin/sh
# KP-FIX-WATCHDOG-LEAK v4：快速版（不做 /proc 全量扫描，高负载下也能秒级完成）
# 顺序很关键：先打补丁封住增殖链，再清场，最后用 procd 起唯一实例
LOG=/tmp/kp_fix4.log
: > $LOG
say(){ echo "$@" >> $LOG; }

say "=== [1] 先封增殖链：init.d 的 start_watchdog 改幂等 ==="
if ! grep -q 'procd_running openclash-watchdog' /etc/init.d/openclash 2>/dev/null; then
  cp /etc/init.d/openclash /etc/init.d/openclash.kp.bak 2>/dev/null
  awk '
  {
    if ($0 ~ /procd_open_instance "openclash-watchdog"/ && !ins) {
      print "\tprocd_running openclash-watchdog >/dev/null && return 0";
      ins = 1
    }
    print
  }' /etc/init.d/openclash > /tmp/oc.init.new 2>/dev/null
  if [ -s /tmp/oc.init.new ]; then
    mv /tmp/oc.init.new /etc/init.d/openclash
    chmod +x /etc/init.d/openclash
    say "  已加幂等判断"
  else
    say "  !! awk 失败"
  fi
else
  say "  已存在，跳过"
fi

say "=== [2] 封增殖链：watchdog 脚本加单实例锁 ==="
WD=/usr/share/openclash/openclash_watchdog.sh
if ! grep -q 'KP-OC-WD-LOCK' "$WD" 2>/dev/null; then
  cp "$WD" "$WD.kp.bak" 2>/dev/null
  awk '
  NR == 1 {
    print "#!/bin/sh"
    print "# KP-OC-WD-LOCK: 单实例锁（防 procd/cron 重复拉起导致指数增殖）"
    print "KP_WD_LOCK=/var/run/openclash_watchdog.pid"
    print "if [ -f \"$KP_WD_LOCK\" ]; then"
    print "  _oldwdp=$(cat \"$KP_WD_LOCK\" 2>/dev/null)"
    print "  if [ -n \"$_oldwdp\" ] && [ -d \"/proc/$_oldwdp\" ]; then exit 0; fi"
    print "fi"
    print "echo $$ > \"$KP_WD_LOCK\""
    next
  }
  { print }' "$WD" > /tmp/wd.new 2>/dev/null
  if [ -s /tmp/wd.new ]; then
    mv /tmp/wd.new "$WD"; chmod +x "$WD"
    say "  已加锁"
  else
    say "  !! awk 失败"
  fi
else
  say "  已存在，跳过"
fi

say "=== [3] 清场：杀光所有 watchdog（pgrep 快速判定，最多 6 轮）==="
i=0
while [ $i -lt 6 ]; do
  n=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)
  say "  round $i: $n"
  [ "$n" -eq 0 ] && break
  pkill -9 -f 'openclash_watchdog.sh' 2>/dev/null
  sleep 1
  i=$((i+1))
done

say "=== [4] 注销 procd 实例并起唯一一份 ==="
ubus call service delete '{"name":"openclash","instance":"openclash-watchdog"}' 2>&1 | head -2 >> $LOG
sleep 1
sh -c '. /lib/functions.sh; procd_open_instance "openclash-watchdog"; procd_set_param command "/usr/share/openclash/openclash_watchdog.sh"; procd_close_instance' 2>&1 | head -3 >> $LOG
sleep 4
say "  实例数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"

say "=== [5] 兜底守护（每 5 分钟收敛到 1 份）==="
cat > /usr/bin/kp-oc-wd-guard.sh <<'GUARD'
#!/bin/sh
# KP-OC-WD-GUARD: 保证 openclash_watchdog.sh 只有一份
cnt=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)
[ "$cnt" -le 1 ] && exit 0
pids=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | sort -n)
keep=$(echo "$pids" | head -1)
for p in $pids; do
  [ "$p" = "$keep" ] || kill -9 "$p" 2>/dev/null
done
echo "$(date '+%F %T') watchdog $cnt -> 1 (keep $keep)" >> /tmp/kp-oc-wd-guard.log
GUARD
chmod +x /usr/bin/kp-oc-wd-guard.sh
grep -q 'kp-oc-wd-guard' /etc/crontabs/root 2>/dev/null || echo '*/5 * * * * /usr/bin/kp-oc-wd-guard.sh #kp-oc-wd-guard' >> /etc/crontabs/root

say "=== [6] 结果 ==="
say "watchdog: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)   总进程: $(ps w | wc -l)"
say -n "loadavg: "; cat /proc/loadavg >> $LOG
free -m | head -2 >> $LOG
say "crontab:"; cat /etc/crontabs/root | sed 's/^/  /' >> $LOG
cat $LOG
