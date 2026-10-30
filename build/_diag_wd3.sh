#!/bin/sh
WD=/usr/share/openclash/openclash_watchdog.sh
echo "===== 1. 工具可用性 ====="
echo "setsid: $(command -v setsid || echo 无)"
echo "nohup:  $(command -v nohup || echo 无)"
echo "pgrep:  $(command -v pgrep || echo 无)"
echo
echo "===== 2. 前台跑 5 秒观察（后台起、带日志）====="
rm -f /var/run/openclash_watchdog.pid /tmp/wdtest.log
nohup sh "$WD" > /tmp/wdtest.log 2>&1 &
newpid=$!
echo "启动 pid=$newpid"
sleep 5
echo "5 秒后:"
echo "  /proc/$newpid 存在? $([ -d /proc/$newpid ] && echo 是 || echo 否)"
echo "  pgrep 计数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
echo "  锁文件: $(cat /var/run/openclash_watchdog.pid 2>/dev/null || echo 无)"
echo "  ---- 日志前 15 行 ----"
head -15 /tmp/wdtest.log 2>/dev/null
echo "  ---- 大小: $(wc -c < /tmp/wdtest.log 2>/dev/null) ----"
echo
echo "===== 3. sh -x 前 30 行执行轨迹（2 秒后掐掉）====="
sh -x "$WD" > /tmp/wdx.log 2>&1 &
xp=$!
sleep 2
kill -9 $xp 2>/dev/null
head -40 /tmp/wdx.log 2>/dev/null
echo
echo "===== 4. 结果状态 ====="
echo "watchdog 实例: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
echo "总进程: $(ps w | wc -l)"
cat /proc/loadavg
