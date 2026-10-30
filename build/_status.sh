#!/bin/sh
echo "===== 修复日志尾部 ====="
tail -32 /tmp/kp_fix3.log 2>/dev/null || echo "(无 kp_fix3.log)"
echo
echo "===== 当前状态 ====="
echo "watchdog 实例: $(ps w | grep -c '[o]penclash_watchdog.sh')"
echo "总进程数:      $(ps w | wc -l)"
echo -n "loadavg:       "; cat /proc/loadavg
free -m | head -2
echo
echo "===== crontab ====="
cat /etc/crontabs/root
echo
echo "===== 补丁是否落地 ====="
grep -c 'KP-OC-WD-LOCK' /usr/share/openclash/openclash_watchdog.sh 2>/dev/null
grep -c 'procd_running openclash-watchdog' /etc/init.d/openclash 2>/dev/null
ls -l /usr/bin/kp-oc-wd-guard.sh 2>/dev/null
echo
echo "===== clash 进程 ====="
ps w | grep '[c]lash -d' | head -2
echo
echo "===== 8080 目录占用 ====="
du -sh /overlay/nradio-apps/openwrt-luci-8080 2>/dev/null
ls -d /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | wc -l
