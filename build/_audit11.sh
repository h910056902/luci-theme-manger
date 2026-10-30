#!/bin/sh
echo "===== 1. 407 认证来源确认 ====="
uci show openclash 2>/dev/null | grep -iE 'auth|username|password' | sed 's/password=.*/password=***/' | head -5
echo
echo "===== 2. logrotate 是否正确轮转 openclash 日志 ====="
cat /etc/logrotate.d/openclash 2>/dev/null || echo "  无 openclash 轮转配置"
ls -l /etc/logrotate.d/ 2>/dev/null | head -6
echo
echo "===== 3. rc.local 内容（防止有残留试验代码）====="
cat /etc/rc.local 2>/dev/null | grep -v '^#' | grep -v '^$' | head -8
echo
echo "===== 4. watchdog 长期稳定性（现在仍应为 1）====="
echo "  实例数: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)"
echo "  锁 PID: $(cat /var/run/openclash_watchdog.pid 2>/dev/null)（存活: $([ -d /proc/$(cat /var/run/openclash_watchdog.pid 2>/dev/null) ] && echo 是 || echo 否)）"
echo
echo "===== 5. 泄漏是否彻底停了（与 22:00 前后对比）===="
echo "  总进程: $(ps w | wc -l)  （修复前 4135）"
echo "  watchdog: $(pgrep -f 'openclash_watchdog.sh' 2>/dev/null | wc -l)  （修复前 2201）"
echo
echo "===== 6. dropbear 加固建议参数现状 ====="
uci show dropbear 2>/dev/null | head -8
echo
echo "===== 7. 是否存在自动升级包的定时任务（会动到 veth 环境）===="
grep -rn 'apk upgrade\|opkg upgrade' /etc/crontabs/root /etc/uci-defaults/ 2>/dev/null | head -3 || echo "  无（好）"
echo
echo "===== 8. 结论性健康总览 ====="
uptime
echo "  进程: $(ps w | wc -l)  swap: $(free -m | awk '/Swap/{print $3"MB 已用"}')"
