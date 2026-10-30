#!/bin/sh
echo "===== 1. 代理端口拒绝的精确定位 ====="
curl -v -m 6 -x http://127.0.0.1:7893 https://www.gstatic.com/generate_204 2>&1 | grep -E 'Connected|refused|reset|timed|Trying' | head -4
echo "-- 防火墙里针对本机/clash 端口的规则 --"
nft list ruleset 2>/dev/null | grep -iE '7890|7891|7892|7893|7874' | head -12
echo "-- openclash 自定义链 --"
nft list ruleset 2>/dev/null | grep -iE 'chain .*openclash' | head -8
echo "-- clash 核心日志尾（有无 reject/timeout）--"
tail -30 /tmp/openclash.log 2>/dev/null | grep -viE '\[TCP\]|\[UDP\]' | tail -6
echo
echo "===== 2. 用 LAN 客户端视角测（192.168.66.245 同网段语义）====="
ip=$(ip -4 addr show br-lan 2>/dev/null | grep -o 'inet [0-9.]*' | awk '{print $2}')
echo "  br-lan ip=$ip"
curl -s -m 8 -x "http://$ip:7893" -o /dev/null -w "  $ip:7893 -> %{http_code} (%{time_total}s)\n" https://www.gstatic.com/generate_204 2>&1
echo
echo "===== 3. theme-backup 生成源头（全仓库搜）====="
cd /tmp && grep -rln 'theme-backup' /tmp/luci-theme-src 2>/dev/null | head -3
echo "-- 本地仓库（挂载路径可能不同，直接搜设备 web 根）--"
grep -rln 'theme-backup' /www/luci-static/ 2>/dev/null | head -5
grep -rln 'theme-backup' /usr/share/luci/ 2>/dev/null | head -5
grep -rln 'theme-backup' /overlay/nradio-apps/openwrt-luci-8080/www/ 2>/dev/null | head -5
echo
echo "===== 4. clash 核心版本与运行时长 ====="
/etc/openclash/clash -v 2>/dev/null | head -2
echo "  clash 运行时长: $(ps w | grep '[c]lash -d' | awk '{print $1}')  系统已运行 $(( $(cut -d. -f1 /proc/uptime) / 3600 )) 小时"
