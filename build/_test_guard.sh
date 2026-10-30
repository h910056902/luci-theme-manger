#!/bin/sh
echo "===== 1. 当前 watchdog（基线）====="
pgrep -f 'openclash_watchdog.sh' 2>/dev/null | tr '\n' ' '
echo
echo "===== 2. 造一个假实例（cmdline 含 openclash_watchdog.sh）====="
cp /bin/sleep /tmp/fakewd
chmod +x /tmp/fakewd
nohup /tmp/fakewd 300 openclash_watchdog.sh >/dev/null 2>&1 &
sleep 1
echo "  现在计数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
echo
echo "===== 3. 触发兜底守护 ====="
/usr/bin/kp-oc-wd-guard.sh
sleep 1
echo "  收敛后计数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
echo "  守护日志: $(cat /tmp/kp-oc-wd-guard.log 2>/dev/null | tail -2)"
echo
echo "===== 4. 清理测试残留 ====="
pgrep -f 'fakewd' 2>/dev/null | while read -r p; do kill -9 "$p" 2>/dev/null; done
rm -f /tmp/fakewd
echo
echo "===== 5. 最终健康检查 ====="
echo "  watchdog : $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l) 个（lock=$(cat /var/run/openclash_watchdog.pid 2>/dev/null)）"
echo "  总进程   : $(ps w | wc -l)"
echo "  clash    : $(pgrep -f 'clash -d' 2>/dev/null | wc -l) 个"
echo "  接口监听 : $(netstat -ln 2>/dev/null | grep -c -E ':7890|:9091') 个"
echo -n "  loadavg  : "; cat /proc/loadavg
free -m | head -3
df -h /overlay | tail -1
