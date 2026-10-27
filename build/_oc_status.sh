#!/bin/sh
echo "== 进程 =="
pidof clash >/dev/null 2>&1 && echo "  clash PID=$(pidof clash)" || echo "  clash 未运行"
ps w | grep '[c]lash' | head -2

echo "== 端口 =="
netstat -lnt 2>/dev/null | grep -E '7890|7891|7892|7874|9090' || echo "  未监听"

echo "== 日志 =="
tail -10 /etc/openclash/openclash.log 2>/dev/null

echo "== 配置 =="
ls -l /etc/openclash/config/ 2>/dev/null | head -4
[ -f /etc/openclash/config/e_bbydy.yaml ] && echo "  节点数: $(grep -c '^  - name:' /etc/openclash/config/e_bbydy.yaml 2>/dev/null)"

echo "== API =="
SEC=$(uci -q get openclash.config.dashboard_password 2>/dev/null)
curl -s -m 6 -H "Authorization: Bearer $SEC" http://127.0.0.1:9090/version 2>/dev/null | head -c 120
echo
