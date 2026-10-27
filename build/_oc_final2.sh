#!/bin/sh
echo "== 1. DNS 工具 =="
for c in nslookup dig host getent; do printf "  %-9s %s\n" "$c" "$(command -v $c 2>/dev/null || echo -)"; done

echo "== 2. DNS 是否劫持（期望 198.18.x.x）=="
ping -c1 -W2 google.com 2>/dev/null | head -2
echo "-- 通过路由器 DNS --"
nslookup google.com 192.168.66.1 2>&1 | tail -5

echo "== 3. 补守护 cron =="
if ! crontab -l 2>/dev/null | grep -q openclash_watchdog; then
	echo '*/1 * * * * /usr/share/openclash/openclash_watchdog.sh' >> /etc/crontabs/root
	echo "  已添加 watchdog"
else
	echo "  已存在"
fi
/etc/init.d/cron restart >/dev/null 2>&1
crontab -l 2>/dev/null | grep -i openclash

echo "== 4. clash 内存 =="
for p in $(pidof clash); do awk -v p="$p" '/VmRSS/{print "  PID " p " " $2/1024 " MB"}' /proc/$p/status 2>/dev/null; done

echo "== 5. 端口总览 =="
netstat -lnt 2>/dev/null | grep -E '7890|7891|7892|7893|7895|7874|9090' | awk '{print "  " $4}'
