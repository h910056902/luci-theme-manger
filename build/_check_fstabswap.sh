#!/bin/sh
echo "== /etc/init.d/fstab 里与 swap 相关的行 =="
grep -n 'swap' /etc/init.d/fstab 2>/dev/null | head -8
echo "== 启动脚本里是否有 swapon =="
grep -rn 'swapon' /etc/init.d/ /lib/functions/ 2>/dev/null | head -8
echo "== rc.d =="
ls /etc/rc.d/ | grep -E 'fstab|swap'
echo "== 当前 swap 生效情况 =="
cat /proc/swaps
