#!/bin/sh
echo "== 1. 前置检查 =="
ls -l /etc/openclash/core/clash_meta 2>/dev/null || { echo "  内核缺失，停止"; exit 1; }
/etc/openclash/core/clash_meta -v 2>&1 | head -2
mkdir -p /etc/openclash/config /etc/openclash/history /etc/openclash/core /etc/openclash/rule_provider
chmod 755 /etc/openclash/config /etc/openclash/history
ls -l /etc/openclash/config/ 2>/dev/null | head -3

echo "== 2. 依赖命令 =="
for c in jsonfilter iptables nft curl; do printf "  %-10s %s\n" "$c" "$(command -v $c 2>/dev/null || echo -)"; done
iptables -V 2>/dev/null | head -1
nft --version 2>/dev/null | head -1

echo "== 3. 启动 =="
uci set openclash.config.enable='1'
uci commit openclash
[ -x /etc/init.d/openclash ] && chmod 755 /etc/init.d/openclash
/etc/init.d/openclash enable 2>/dev/null
/etc/init.d/openclash restart 2>&1 | head -5

echo "== 4. 等待（最多 90s）=="
i=0
while [ $i -lt 18 ]; do
	i=$((i+1))
	sleep 5
	pidof clash >/dev/null 2>&1 && break
done

echo "== 5. 状态 =="
pidof clash >/dev/null 2>&1 && echo "  clash PID=$(pidof clash)" || echo "  clash 未运行"
ps w | grep '[c]lash' | head -2
netstat -lnt 2>/dev/null | grep -E '7890|7891|7892|7874|9090' || echo "  代理端口未监听"

echo "== 6. 日志尾部 =="
tail -12 /etc/openclash/openclash.log 2>/dev/null || tail -12 /tmp/openclash.log 2>/dev/null

echo "== 7. 配置文件 =="
ls -l /etc/openclash/config/*.yaml 2>/dev/null | head -3
grep -c 'name:' /etc/openclash/config/e_bbydy.yaml 2>/dev/null
