#!/bin/sh
echo "== 1. OpenClash 服务 =="
ps w | grep -E '[c]lash' | head -3
echo -n "  代理端口: "; netstat -lnt 2>/dev/null | grep -cE ':7890|:7891|:7892|:9090'
uci -q get openclash.config.enable | sed 's/^/  enable=/'

echo
echo "== 2. 外网（直连）=="
curl -s -o /dev/null -m 8 -w "  百度: %{http_code}\n" http://www.baidu.com
ping -c 1 -W 3 223.5.5.5 >/dev/null 2>&1 && echo "  ICMP: 通" || echo "  ICMP: 不通"

echo
echo "== 3. 代理链路（走 7890）=="
curl -s -o /dev/null -m 15 -x http://127.0.0.1:7890 -w "  经代理访问 google: %{http_code}\n" https://www.google.com 2>/dev/null
curl -s -m 15 -x http://127.0.0.1:7890 https://api.ipify.org 2>/dev/null | head -1 | sed 's/^/  代理出口 IP: /'

echo
echo "== 4. 面板与 OpenClash 页面 =="
curl -s -o /dev/null -m 8 -w "  8080 面板: %{http_code}\n" http://192.168.66.1:8080/
curl -s -o /dev/null -m 8 -w "  80 主界面: %{http_code}\n" http://192.168.66.1/
curl -s -o /dev/null -m 8 -w "  OpenClash 页: %{http_code}\n" http://192.168.66.1/cgi-bin/luci/admin/services/openclash/ 2>/dev/null

echo
echo "== 5. 磁盘 =="
df -h /overlay | tail -1
du -sm /etc/openclash 2>/dev/null
