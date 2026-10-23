#!/bin/sh
K=$(uname -r)
echo "kernel=$K"
echo "== zram 模块文件 =="
ls -l /lib/modules/$K/zram.ko* 2>/dev/null || echo "无 zram.ko"
find /lib/modules/$K -name 'zram*' 2>/dev/null | head -5
echo "== 已装包 =="
opkg list-installed 2>/dev/null | grep -iE 'zram|swap' || echo "无相关包"
echo "== 尝试加载 =="
modprobe zram 2>&1 && echo "modprobe zram OK"
ls -d /sys/block/zram* 2>/dev/null || echo "仍无 zram 设备"
echo "== 内核配置 =="
grep -i 'zram' /boot/config-* 2>/dev/null | head -3
zcat /proc/config.gz 2>/dev/null | grep -i 'ZRAM\|ZSMALLOC' | head -5 || echo "无 /proc/config.gz"
