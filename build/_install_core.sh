#!/bin/sh
URL=https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/mihomo-linux-arm64-v1.19.33.gz
mkdir -p /etc/openclash/core
cd /tmp || exit 1
rm -f mihomo.gz

echo "== 下载内核 =="
curl -L --retry 2 -m 180 -o mihomo.gz "$URL" 2>/dev/null
ls -l mihomo.gz 2>/dev/null || { echo "下载失败"; exit 1; }

echo "== 解压安装 =="
gunzip -c mihomo.gz > /etc/openclash/core/clash_meta
chmod 755 /etc/openclash/core/clash_meta
rm -f mihomo.gz
ls -l /etc/openclash/core/clash_meta
/etc/openclash/core/clash_meta -v 2>&1 | head -3

echo "== 启动 OpenClash =="
/etc/init.d/openclash enable 2>/dev/null
/etc/init.d/openclash restart >/dev/null 2>&1
sleep 6
if pidof openclash >/dev/null 2>&1; then
	echo "  openclash PID: $(pidof openclash)"
else
	echo "  未运行，日志："
	logread 2>/dev/null | grep -iE 'openclash|clash' | tail -8
fi

echo "== 端口 =="
netstat -lnt 2>/dev/null | grep -E ':7890|:7891|:7892|:7893|:9090' | head -6
echo "== rubust 检查 =="
curl -s -o /dev/null -m 5 -w "  9090 API: %{http_code}\n" http://127.0.0.1:9090/ 2>/dev/null
