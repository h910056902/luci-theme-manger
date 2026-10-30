#!/bin/sh
# KP-FIX-WATCHDOG-LEAK v2
# 根因: /usr/share/openclash/openclash_watchdog.sh 末尾是 `while true; ... sleep 60; done`
#       的常驻守护；上一轮误加 crontab `*/1 * * * *` 每分钟再拉起一份，
#       脚本无单实例锁 -> 2 天累积 386 份守护 + 376 个 sleep，load ~100、CPU 打满。
# 正确结构: OpenClash 官方用 procd 托管唯一实例（init.d/openclash: start_watchdog）。
# 本脚本: 删 cron -> 杀存量 -> 用 procd 注册唯一实例 -> 验证
LOG=/tmp/kp_fix_watchdog.log
: > $LOG
say() { echo "$@" >> $LOG; }

say "=== [1] 删除重复拉起的 cron 行 ==="
cp /etc/crontabs/root /etc/crontabs/root.kp.bak
sed -i '/openclash_watchdog/d' /etc/crontabs/root
say "剩余 crontab:"; cat /etc/crontabs/root >> $LOG

say ""
say "=== [2] 清理前统计 ==="
say "watchdog 实例: $(ps w | grep -c '[o]penclash_watchdog.sh')  总进程: $(ps w | wc -l)"

say ""
say "=== [3] 杀掉全部 watchdog 实例 ==="
pkill -f 'openclash_watchdog.sh' 2>/dev/null
sleep 3
pkill -9 -f 'openclash_watchdog.sh' 2>/dev/null
sleep 1
say "剩余: $(ps w | grep -c '[o]penclash_watchdog.sh')"

say ""
say "=== [4] 清理孤儿 sleep（父进程已死、命令为 sleep 60）==="
n=0
for p in $(ls /proc | grep -E '^[0-9]+$'); do
  cmd=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null | sed 's/ *$//')
  if [ "$cmd" = "sleep 60" ]; then
    ppid=$(awk '/^PPid:/{print $2}' /proc/$p/status 2>/dev/null)
    [ "$ppid" = "1" ] && { kill -9 "$p" 2>/dev/null; n=$((n+1)); }
  fi
done
say "已清理孤儿 sleep: $n"

say ""
say "=== [5] 用 procd 注册唯一实例（复刻 init.d/openclash 的 start_watchdog）==="
cat > /tmp/_kp_wd_register.sh <<'EOF'
#!/bin/sh
. /lib/functions.sh
procd_open_instance "openclash-watchdog"
procd_set_param command "/usr/share/openclash/openclash_watchdog.sh"
procd_close_instance
EOF
sh /tmp/_kp_wd_register.sh 2>&1 | head -5 >> $LOG
sleep 4
say "watchdog 实例数: $(ps w | grep -c '[o]penclash_watchdog.sh')"
say "procd 实例:"
ubus call service list '{"name":"openclash"}' 2>/dev/null | tr ',' '\n' | grep -i 'watchdog' | head -3 >> $LOG

say ""
say "=== [6] 结果 ==="
say "总进程数: $(ps w | wc -l)"
say -n "loadavg: "; cat /proc/loadavg >> $LOG
free -m >> $LOG
say ""
say "clash 进程:"; ps w | grep '[c]lash -d' >> $LOG
cat $LOG
