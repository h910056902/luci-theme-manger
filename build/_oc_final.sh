#!/bin/sh
echo "== 1. DNS 劫持（fake-ip 应为 198.18.x.x）=="
nslookup google.com 192.168.66.1 2>/dev/null | tail -4
echo "-- 直连 dnsmasq 端口 7874 --"
nslookup github.com 127.0.0.1 2>/dev/null | tail -3

echo "== 2. openclash 链规则统计 =="
echo -n "  mangle openclash 规则数: "
iptables -t mangle -S openclash 2>/dev/null | grep -c '^-A'
iptables -t mangle -S openclash 2>/dev/null | head -4
echo -n "  nat openclash 规则数:    "
iptables -t nat -S openclash 2>/dev/null | grep -c '^-A'

echo "== 3. 守护脚本与定时任务 =="
ls /usr/share/openclash/ | grep -i watchdog
crontab -l 2>/dev/null | grep -i openclash || echo "  crontab 无 openclash 条目"

echo "== 4. 资源占用 =="
ps w | grep '[c]lash' | awk '{print "  RSS=" $6}'
free -m 2>/dev/null | head -2

echo "== 5. 自启 =="
ls /etc/rc.d/ | grep -i openclash
