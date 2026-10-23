#!/bin/sh
echo "== zram 设备 =="
ls -d /sys/block/zram* 2>/dev/null || echo "无 zram"
echo "== zram 服务 =="
ls -l /etc/init.d/zram-swap /etc/rc.d/S*zram* 2>/dev/null || echo "无 zram-swap 服务"
cat /sys/block/zram0/disksize 2>/dev/null
echo "== 当前 swap =="
cat /proc/swaps
echo "== swappiness =="
cat /proc/sys/vm/swappiness 2>/dev/null
echo "== swap 工具 =="
which mkswap swapon swapoff 2>/dev/null
echo "== 分区与空间 =="
df -m /overlay /mnt/storage/data 2>/dev/null | tail -3
echo "== 挂载类型 =="
awk '$2=="/overlay" || $2=="/mnt/storage/data" {print $1, $2, $3}' /proc/mounts
echo "== 现有 swapfile =="
ls -lh /overlay/swapfile /mnt/storage/data/swapfile 2>/dev/null || echo "无"
echo "== fstab swap 段 =="
uci show fstab 2>/dev/null | grep -i swap || echo "无"
