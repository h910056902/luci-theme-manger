#!/bin/sh
# KP-PERSIST v1: 修固件差异 + 落实刷机后可恢复
LOG=/tmp/kp_persist.log
: > $LOG
say(){ echo "$@" >> $LOG; }

say "=== [1] 修兜底守护：本固件没有 setsid，改用 nohup ==="
sed -i 's|setsid "\$WD" >/dev/null 2>&1 &|nohup sh "$WD" >/dev/null 2>\&1 \&|' /usr/bin/kp-oc-wd-guard.sh
grep -n 'nohup' /usr/bin/kp-oc-wd-guard.sh | sed 's/^/  /' >> $LOG
say "  语法: $(sh -n /usr/bin/kp-oc-wd-guard.sh 2>&1 && echo OK)"

say ""
say "=== [2] keep.d 补齐保留清单 ==="
KEEP=/lib/upgrade/keep.d/nradio-luci-8080
cp "$KEEP" "$KEEP.kp.bak" 2>/dev/null
if ! grep -q '/etc/.app_store.id' "$KEEP"; then
cat >> "$KEEP" <<'EOF'

# ---- KP 追加（2026-10-30）----
# iStore 设备标识：缺失时 store.lua 回退空 arch，前端按 arch 过滤 -> 应用列表全空
/etc/.app_store.id
# 自编译 veth 模块：厂商内核 CONFIG_VETH is not set，缺失则 Docker bridge 网络不可用
/lib/modules/6.12.94/veth.ko
/etc/init.d/kp-veth
/etc/rc.d/S98kp-veth
# Docker 引擎配置（data-root / 镜像加速 / bridge 开关）
/etc/docker/daemon.json
# OpenClash watchdog 兜底守护（防厂商更新后进程泄漏复发）
/usr/bin/kp-oc-wd-guard.sh
EOF
say "  已追加"
else
say "  已存在，跳过"
fi
say "  当前 keep.d 尾部:"; tail -14 "$KEEP" | sed 's/^/    /' >> $LOG

say ""
say "=== [3] 刷机后自动复应用补丁（uci-defaults）==="
cat > /etc/uci-defaults/99-kp-post-upgrade <<'UCI'
#!/bin/sh
# KP-POST-UPGRADE: 固件升级后自动复应用 KP 补丁（本脚本执行成功后会被删除）
LOG=/tmp/kp-post-upgrade.log
: > $LOG
say(){ echo "$@" >> $LOG; }

# 1) OpenClash watchdog 单实例：init.d 幂等
if ! grep -q 'procd_running openclash-watchdog' /etc/init.d/openclash 2>/dev/null; then
  awk '{ if ($0 ~ /procd_open_instance "openclash-watchdog"/ && !ins) {
           print "\tprocd_running openclash-watchdog >/dev/null && return 0"; ins = 1 }
         print }' /etc/init.d/openclash > /tmp/oc.init.new 2>/dev/null
  [ -s /tmp/oc.init.new ] && { mv /tmp/oc.init.new /etc/init.d/openclash; chmod +x /etc/init.d/openclash; say "init.d 幂等补丁已应用"; }
fi

# 2) OpenClash watchdog 脚本 pidfile 单实例锁
WD=/usr/share/openclash/openclash_watchdog.sh
if [ -f "$WD" ] && ! grep -q 'KP-OC-WD-LOCK' "$WD"; then
  awk 'NR == 1 {
    print "#!/bin/sh"
    print "# KP-OC-WD-LOCK: 单实例锁（防 procd/cron 重复拉起导致指数增殖）"
    print "KP_WD_LOCK=/var/run/openclash_watchdog.pid"
    print "if [ -f \"$KP_WD_LOCK\" ]; then"
    print "  _oldwdp=$(cat \"$KP_WD_LOCK\" 2>/dev/null)"
    print "  if [ -n \"$_oldwdp\" ] && [ -d \"/proc/$_oldwdp\" ]; then exit 0; fi"
    print "fi"
    print "echo $$ > \"$KP_WD_LOCK\""
    next }
  { print }' "$WD" > /tmp/wd.new 2>/dev/null
  [ -s /tmp/wd.new ] && { mv /tmp/wd.new "$WD"; chmod +x "$WD"; say "watchdog 锁补丁已应用"; }
fi

# 3) 兜底守护 cron
if [ -x /usr/bin/kp-oc-wd-guard.sh ]; then
  grep -q 'kp-oc-wd-guard' /etc/crontabs/root 2>/dev/null || \
    echo '*/5 * * * * /usr/bin/kp-oc-wd-guard.sh #kp-oc-wd-guard' >> /etc/crontabs/root
fi

# 4) iStore 设备标识（缺失则重新生成，否则商店应用列表为空）
if [ ! -f /etc/.app_store.id ]; then
  ARCH=$(head -1 /etc/apk/arch 2>/dev/null); [ -n "$ARCH" ] || ARCH=aarch64_cortex-a53
  UIDX=$(cat /dev/urandom 2>/dev/null | md5sum | cut -c1-32)
  printf '{"arch":"%s","uid":"%s"}' "$ARCH" "$UIDX" > /etc/.app_store.id
  chmod 644 /etc/.app_store.id
  say "已重建 /etc/.app_store.id"
fi

# 5) kp-veth 开机启用
[ -x /etc/init.d/kp-veth ] && /etc/init.d/kp-veth enable 2>/dev/null

say "完成 $(date '+%F %T')"
exit 0
UCI
chmod +x /etc/uci-defaults/99-kp-post-upgrade
say "  已写入 /etc/uci-defaults/99-kp-post-upgrade"

say ""
say "=== [4] 立即跑一次守护，确认自愈逻辑 ==="
/usr/bin/kp-oc-wd-guard.sh
sleep 2
say "  watchdog 实例: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
say "  锁文件: $(cat /var/run/openclash_watchdog.pid 2>/dev/null || echo 无)"
say "  守护日志:"; tail -3 /tmp/kp-oc-wd-guard.log 2>/dev/null | sed 's/^/    /' >> $LOG

say ""
say "=== [5] 系统状态 ==="
say "总进程: $(ps w | wc -l)"
say -n "loadavg: "; cat /proc/loadavg >> $LOG
free -m | head -2 >> $LOG
cat $LOG
