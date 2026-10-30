#!/bin/sh
# KP-OPTIMIZE v1: 启用 swap + 清理 theme 备份堆积
LOG=/tmp/kp_optimize.log
: > $LOG
say(){ echo "$@" >> $LOG; }

say "=== [1] 启用 swap（512MB swapfile 已存在但从未 swapon）==="
if [ -f /overlay/swapfile ]; then
  swapon /overlay/swapfile 2>&1 | head -2 >> $LOG
  say "  /proc/swaps:"; cat /proc/swaps | sed 's/^/    /' >> $LOG
else
  say "  swapfile 不存在，创建 512MB"
  dd if=/dev/zero of=/overlay/swapfile bs=1M count=512 2>/dev/null
  chmod 600 /overlay/swapfile
  mkswap /overlay/swapfile >/dev/null 2>&1
  swapon /overlay/swapfile
fi

say ""
say "=== [2] 开机自动 swapon（init 脚本，随 keep.d 保留）==="
cat > /etc/init.d/kp-swap <<'INIT'
#!/bin/sh /etc/rc.common
# KP-SWAP: 1GB 内存机型在 Docker/编译 场景下需要交换空间兜底
START=96
boot() { start; }
start() {
  [ -f /overlay/swapfile ] || return 0
  grep -q '/overlay/swapfile' /proc/swaps 2>/dev/null || \
    /sbin/swapon /overlay/swapfile 2>/dev/null
}
stop() {
  grep -q '/overlay/swapfile' /proc/swaps 2>/dev/null && /sbin/swapoff /overlay/swapfile 2>/dev/null
  return 0
}
INIT
chmod +x /etc/init.d/kp-swap
/etc/init.d/kp-swap enable 2>&1 | head -2 >> $LOG
say "  已启用: $(ls -l /etc/rc.d/ | grep -c kp-swap)"

say ""
say "=== [3] 清理 theme 备份堆积（保留最新 3 份）==="
D=/overlay/nradio-apps/openwrt-luci-8080
n0=$(ls -d $D/theme-backup* 2>/dev/null | wc -l)
ls -dt $D/theme-backup* 2>/dev/null | tail -n +4 | while read -r d; do
  rm -rf "$d"
done
n1=$(ls -d $D/theme-backup* 2>/dev/null | wc -l)
say "  theme-backup: $n0 -> $n1"
say "  保留: $(ls -dt $D/theme-backup* 2>/dev/null | head -3 | tr '\n' ' ')"

say ""
say "=== [4] 把 kp-swap 纳入 keep.d ==="
KEEP=/lib/upgrade/keep.d/nradio-luci-8080
grep -q '/etc/init.d/kp-swap' "$KEEP" || cat >> "$KEEP" <<'EOF'
# swap 开机启用脚本（swapfile 本身不备份，恢复后按需重建）
/etc/init.d/kp-swap
/etc/rc.d/S96kp-swap
EOF
say "  keep.d 尾部:"; tail -4 "$KEEP" | sed 's/^/    /' >> $LOG

say ""
say "=== [5] 结果 ==="
free -m
say ""
df -h /overlay | tail -1
say "总进程: $(ps w | wc -l)"
say -n "loadavg: "; cat /proc/loadavg >> $LOG
cat $LOG
