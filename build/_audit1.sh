#!/bin/sh
echo "===== 1. CPU TOP 15 ====="
top -b -n 1 2>/dev/null | head -25
echo
echo "===== 2. 高 CPU 进程（ps 按 %CPU 排序）====="
ps w | sort -k3 -nr 2>/dev/null | head -15
echo
echo "===== 3. 内核态 vs 用户态 ====="
cat /proc/stat | head -1
echo
echo "===== 4. 内存/交换 ====="
free -m
echo
echo "===== 5. Docker 状态 ====="
ps | grep -E 'dockerd|containerd|docker-proxy' | grep -v grep
echo "-- 容器数 --"
ls /overlay/docker/containers 2>/dev/null | wc -l
echo "-- data-root 占用 --"
du -sh /overlay/docker 2>/dev/null
echo
echo "===== 6. kp-veth 开机脚本 ====="
cat /etc/init.d/kp-veth 2>/dev/null
echo
echo "===== 7. veth 加载来源 ====="
lsmod | grep veth
cat /proc/modules | grep -i veth
echo
echo "===== 8. 磁盘 ====="
df -h | head -8
echo
echo "===== 9. 定时任务 ====="
crontab -l 2>/dev/null
ls /etc/cron.d/ 2>/dev/null
echo
echo "===== 10. OpenClash / 代理进程 ====="
ps | grep -E 'clash|mihomo|nikki' | grep -v grep | head -5
