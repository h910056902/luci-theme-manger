#!/bin/sh
echo "===== 1. watchdog 进程状态分布（STAT 列）====="
ps w | grep '[o]penclash_watchdog.sh' | awk '{print $4}' | sort | uniq -c
echo
echo "===== 2. 样本 5 条（PID PPID STAT 命令行）====="
ps w | grep '[o]penclash_watchdog.sh' | head -5
echo
echo "===== 3. 单实例锁状态 ====="
ls -l /var/run/openclash_watchdog.pid 2>/dev/null && echo "锁内 PID: $(cat /var/run/openclash_watchdog.pid 2>/dev/null)" || echo "锁文件不存在"
echo
echo "===== 4. 手动 kill -9 单个样本，看是否真能杀掉 ====="
tp=$(ps w | grep '[o]penclash_watchdog.sh' | head -1 | awk '{print $1}')
echo "目标 PID: $tp"
kill -9 "$tp" 2>&1
sleep 2
if [ -d "/proc/$tp" ]; then
  echo "结果: 仍存在 -> STAT=$(awk '/^State:/{print $2,$3}' /proc/$tp/status 2>/dev/null)"
else
  echo "结果: 已消失"
fi
echo
echo "===== 5. procd 实例列表 ====="
ubus call service list '{"name":"openclash"}' 2>/dev/null | tr ',' '\n' | grep -iE 'watchdog|"running"' | head -8
echo
echo "===== 6. procd 函数位置 ====="
ls -l /lib/functions/procd.sh /lib/functions.sh 2>/dev/null
grep -l 'procd_open_instance' /lib/functions.sh /lib/functions/*.sh 2>/dev/null
echo
echo "===== 7. 近 1 分钟新增 watchdog 数量 ====="
a=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)
sleep 20
b=$(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)
echo "20 秒前: $a  现在: $b"
echo
echo "===== 8. openclash.sh 调用频率来源 ====="
grep -n 'cfg_update_interval\|CFG_UPDATE_INT' /usr/share/openclash/openclash_watchdog.sh | head -5
