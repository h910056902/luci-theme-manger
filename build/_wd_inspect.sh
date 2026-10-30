#!/bin/sh
echo "===== watchdog 进程明细 ====="
ps w | grep '[o]penclash_watchdog.sh'
echo
echo "===== 每个进程的启动秒数与父进程 ====="
for p in $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null); do
  ppid=$(awk '/^PPid:/{print $2}' /proc/$p/status 2>/dev/null)
  start=$(awk '{print $22}' /proc/$p/stat 2>/dev/null)
  echo "pid=$p ppid=$ppid starttime=$start stat=$(awk '/^State:/{print $2}' /proc/$p/status 2>/dev/null)"
done
echo
echo "===== 锁文件 ====="
cat /var/run/openclash_watchdog.pid 2>/dev/null; echo
echo
echo "===== 守护日志 ====="
cat /tmp/kp-oc-wd-guard.log 2>/dev/null | tail -6 || echo "(无日志，说明守护从未触发过收敛)"
echo
echo "===== 守护脚本 cron 是否存在 ====="
grep -c 'kp-oc-wd-guard' /etc/crontabs/root
echo "===== cron 服务是否在跑 ====="
pgrep -f crond 2>/dev/null | wc -l
