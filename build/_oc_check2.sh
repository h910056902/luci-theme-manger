#!/bin/sh
sleep 8
echo "== 进程 =="
ps w | grep -E '[c]lash_meta|[o]penclash|[r]uby' | head -5
echo "== 端口 =="
netstat -lnt 2>/dev/null | grep -E ':7890|:7891|:7892|:7893|:9090|:7874' | head -6
echo "== 服务状态 =="
/etc/init.d/openclash status 2>&1 | head -2
echo "== 日志（最近 20 行）=="
logread 2>/dev/null | grep -iE 'openclash|clash|mihomo' | tail -20
echo "== 配置 =="
ls -l /etc/openclash/config/ 2>/dev/null | head -5
uci show openclash 2>/dev/null | grep -E 'enable|config_path|en_mode|proxy_port|dns_port' | head -8
echo "== 启动日志文件 =="
tail -20 /tmp/openclash.log 2>/dev/null || echo "  无 /tmp/openclash.log"
