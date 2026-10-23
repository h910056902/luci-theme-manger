#!/bin/sh
echo "== squashfs 支持 =="
grep -w squashfs /proc/filesystems || echo "内核无 squashfs（不太可能）"
echo "== loop 设备 =="
ls -l /dev/loop* 2>/dev/null || echo "无 /dev/loop*"
echo "== loop 模块 =="
ls /lib/modules/$(uname -r)/loop.ko 2>/dev/null || echo "无 loop.ko"
modprobe loop 2>&1 && echo "modprobe loop OK"
ls -l /dev/loop* 2>/dev/null | head -3
echo "== unsquashfs =="
which unsquashfs 2>/dev/null || echo "无 unsquashfs"
echo "== 可用空间 =="
df -k /tmp /root | tail -3
