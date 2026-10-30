#!/bin/sh
echo "===== 1. /tmp 真实构成 ====="
df -h /tmp | tail -1
du -sh /tmp/* 2>/dev/null | sort -rh | head -6
echo
echo "===== 2. swap 配置 ====="
cat /etc/config/fstab 2>/dev/null | head -30
echo "-- swapon 状态 --"
cat /proc/swaps
echo "-- swapfile 权限 --"
ls -l /overlay/swapfile
echo
echo "===== 3. 僵尸/D 进程 ====="
ps w | awk '$4 ~ /Z|D/' | head -5
echo "总进程: $(ps w | wc -l)"
echo
echo "===== 4. crontab ====="
cat /etc/crontabs/root
echo
echo "===== 5. theme 备份目录（按时间）====="
ls -dt /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | head -3
ls -d /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | wc -l
echo "总占用: $(du -sh /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | awk -F'\t' '{s+=$1} END {print s" KB"}')"
echo
echo "===== 6. 自启脚本清单 ====="
ls /etc/rc.d/ | grep -E 'S9|S8' | head -12
echo
echo "===== 7. OpenClash 现状 ====="
echo "clash pid: $(pidof clash)"
echo "watchdog: $(pgrep -f 'openclash_watchdog.sh' | wc -l)"
echo "代理端口监听:"
netstat -ln 2>/dev/null | grep -E ':7890|:7891|:7892|:9090|:9091' | head -5
