#!/bin/sh
echo "== 停止循环 =="
killall -9 openclash.sh 2>/dev/null
killall -9 clash_meta 2>/dev/null
sleep 1

echo "== 补建配置目录 =="
mkdir -p /etc/openclash/config
chmod 755 /etc/openclash/config
ls -ld /etc/openclash/config

echo "== 放入已下载的订阅 =="
if [ ! -s /etc/openclash/config/e_bbydy.yaml ]; then
	[ -s /tmp/test_sub.yaml ] || curl -sL -m 30 -A 'clash-verge/v2.4.5' -o /tmp/test_sub.yaml \
		'https://e.bbydy.org/api/bby/client/subscribe?token=aae6a0a85203674b697f43c7987160a4'
	cp /tmp/test_sub.yaml /etc/openclash/config/e_bbydy.yaml
fi
ls -l /etc/openclash/config/
head -2 /etc/openclash/config/e_bbydy.yaml

echo "== 启动 =="
uci set openclash.config.enable='1'
uci commit openclash
/etc/init.d/openclash start >/dev/null 2>&1

for i in 1 2 3 4 5 6; do
	sleep 8
	p=$(netstat -lnt 2>/dev/null | grep -cE ':7890|:7892|:9090')
	echo "  第 ${i} 次：clash_meta=$(ps w | grep -c '[c]lash_meta') 端口=$p"
	[ "$p" -gt 0 ] && break
done

echo "== 结果 =="
ps w | grep -E '[c]lash_meta' | head -2
netstat -lnt 2>/dev/null | grep -E ':7890|:7891|:7892|:7893|:9090|:7874'
curl -s -o /dev/null -m 5 -w "  9090 API: %{http_code}\n" http://127.0.0.1:9090/
echo "== 日志 =="
tail -12 /tmp/openclash.log 2>/dev/null
