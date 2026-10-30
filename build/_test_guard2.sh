#!/bin/sh
echo "===== 1. 基线 ====="
echo "  watchdog: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)  真实 PID: $(cat /var/run/openclash_watchdog.pid 2>/dev/null)"
echo
echo "===== 2. 造假实例 /tmp/fake_openclash_watchdog.sh ====="
printf '#!/bin/sh\nwhile :; do sleep 5; done\n' > /tmp/fake_openclash_watchdog.sh
chmod +x /tmp/fake_openclash_watchdog.sh
nohup /tmp/fake_openclash_watchdog.sh >/dev/null 2>&1 &
sleep 2
echo "  计数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
echo "  明细: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | tr '\n' ' ')"
echo
echo "===== 3. 触发兜底守护 ====="
/usr/bin/kp-oc-wd-guard.sh
sleep 2
echo "  收敛后计数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
echo "  明细: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | tr '\n' ' ')"
echo "  守护日志: $(tail -2 /tmp/kp-oc-wd-guard.log 2>/dev/null)"
echo
echo "===== 4. 清理残留 ====="
[ -f /tmp/fake_openclash_watchdog.sh ] && rm -f /tmp/fake_openclash_watchdog.sh
echo "  完成"
echo
echo "===== 5. 最终状态 ====="
echo "  watchdog: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)  总进程: $(ps w | wc -l)"
echo -n "  loadavg: "; cat /proc/loadavg
