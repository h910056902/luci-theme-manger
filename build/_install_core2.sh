#!/bin/sh
U=https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/mihomo-linux-arm64-v1.19.33.gz
mkdir -p /etc/openclash/core
cd /tmp || exit 1
rm -f mihomo.gz

for m in "https://ghproxy.net" "https://gh-proxy.com" "https://ghfast.top"; do
	echo "== 尝试 $m =="
	curl -sL --retry 1 -m 240 -o mihomo.gz "$m/$U" 2>/dev/null
	sz=$(wc -c < mihomo.gz 2>/dev/null || echo 0)
	echo "  下载大小: $sz"
	[ "$sz" -gt 1000000 ] && break
	rm -f mihomo.gz
done

[ -s mihomo.gz ] || { echo "全部镜像失败"; exit 1; }

echo "== 安装内核 =="
gunzip -c mihomo.gz > /etc/openclash/core/clash_meta || { echo "解压失败"; exit 1; }
chmod 755 /etc/openclash/core/clash_meta
rm -f mihomo.gz
ls -l /etc/openclash/core/clash_meta
/etc/openclash/core/clash_meta -v 2>&1 | head -2

echo "== 启动 OpenClash =="
/etc/init.d/openclash enable 2>/dev/null
/etc/init.d/openclash restart >/dev/null 2>&1
sleep 8
if pidof openclash >/dev/null 2>&1; then
	echo "  PID: $(pidof openclash)"
else
	echo "  未运行；日志："
	logread 2>/dev/null | grep -iE 'openclash|clash' | tail -10
fi

echo "== 端口 =="
netstat -lnt 2>/dev/null | grep -E ':7890|:7891|:7892|:7893|:9090' | head -6
curl -s -o /dev/null -m 5 -w "  9090 API: %{http_code}\n" http://127.0.0.1:9090/
