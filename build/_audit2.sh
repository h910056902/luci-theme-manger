#!/bin/sh
echo "===== 进程总量 ====="
echo "总进程数: $(ps w | wc -l)"
echo "watchdog 实例: $(ps w | grep -c '[o]penclash_watchdog.sh')"
echo "sleep 60 实例: $(ps w | grep -c '[s]leep 60')"
echo "openclash_get_network 实例: $(ps w | grep -c '[o]penclash_get_network.lua')"
echo "僵尸进程: $(ps w | grep -c '^ *[0-9]* *[0-9]* .*Z')"
echo
echo "===== watchdog 脚本内容 ====="
cat /usr/share/openclash/openclash_watchdog.sh
echo
echo "===== watchdog 进程树（父进程分布）====="
ps w | grep '[o]penclash_watchdog.sh' | awk '{print $1, $2, $3}' | head -20
echo "--- 父 PID 计数 ---"
ps w | grep '[o]penclash_watchdog.sh' | awk '{print $2}' | sort | uniq -c | sort -rn | head -10
echo
echo "===== D 状态进程（不可中断 IO）====="
ps w | awk '$3 ~ /D/ {print}' | head -10
echo
echo "===== /proc/loadavg ====="
cat /proc/loadavg
echo
echo "===== 进程数最多的命令 TOP5 ====="
ps w | awk '{print $5}' | sort | uniq -c | sort -rn | head -8
echo
echo "===== 文件描述符/线程最多的进程 ====="
for p in $(ls /proc | grep -E '^[0-9]+$' | head -200); do n=$(ls /proc/$p/task 2>/dev/null | wc -l); if [ "$n" -gt 5 ]; then echo "$p threads=$n $(cat /proc/$p/comm 2>/dev/null)"; fi; done | head -10
echo
echo "===== 内存 top ====="
free -m
