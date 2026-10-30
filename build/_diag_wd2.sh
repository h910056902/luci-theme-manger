#!/bin/sh
WD=/usr/share/openclash/openclash_watchdog.sh
echo "===== 1. 直接执行 3 秒，看输出与退出码 ====="
timeout 3 sh "$WD" 2>&1 | head -20
echo "退出码: $?"
echo
echo "===== 2. 脚本前 60 行（含注入的锁）====="
sed -n '1,60p' "$WD"
echo
echo "===== 3. 锁文件 ====="
ls -l /var/run/openclash_watchdog.pid 2>/dev/null || echo "无锁文件"
echo
echo "===== 4. OpenClash 关键状态 ====="
uci get openclash.config.enable 2>/dev/null
uci get openclash.config.config_update_interval 2>/dev/null
echo "clash pid: $(pidof clash)"
echo
echo "===== 5. 第 165-215 行（外层循环条件）====="
sed -n '165,215p' "$WD"
