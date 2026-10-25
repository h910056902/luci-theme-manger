#!/bin/sh
echo "== 清理卡住的进程与残缺内核 =="
killall -9 openclash.sh 2>/dev/null
killall -9 clash_meta 2>/dev/null
sleep 1
ls -l /etc/openclash/core/clash_meta 2>/dev/null
rm -f /etc/openclash/core/clash_meta
echo "  已删除残缺内核"

U=https://github.com/MetaCubeX/mihomo/releases/download/v1.19.33/mihomo-linux-arm64-v1.19.33.gz
cd /tmp || exit 1
rm -f mihomo.gz
OK=0

for m in "https://ghproxy.net" "https://gh-proxy.com" "https://ghfast.top"; do
	echo "== 镜像 $m =="
	total=$(curl -sIL -m 30 "$m/$U" 2>/dev/null | tr -d '\r' | awk 'tolower($1)=="content-length:"{v=$2} END{print v}')
	echo "  期望大小: ${total:-未知}"
	[ -n "$total" ] || continue
	rm -f mihomo.gz
	n=0
	while [ "$n" -lt 15 ]; do
		n=$((n+1))
		curl -sL -C - -m 120 -o mihomo.gz "$m/$U" 2>/dev/null
		sz=$(wc -c < mihomo.gz 2>/dev/null || echo 0)
		echo "    第 $n 次: $sz / $total"
		[ "$sz" -ge "$total" ] && { OK=1; break; }
	done
	[ "$OK" = "1" ] && break
done

if [ "$OK" != "1" ]; then
	echo "下载未完成，保留 mihomo.gz 供下次续传"
	exit 1
fi

echo "== 校验并安装 =="
gunzip -t mihomo.gz 2>/dev/null && echo "  gzip 校验通过" || { echo "  gzip 损坏"; exit 1; }
gunzip -c mihomo.gz > /etc/openclash/core/clash_meta
chmod 755 /etc/openclash/core/clash_meta
rm -f mihomo.gz
ls -l /etc/openclash/core/clash_meta
/etc/openclash/core/clash_meta -v 2>&1 | head -2

echo "== 启动 OpenClash =="
uci set openclash.config.enable='1' 2>/dev/null
uci commit openclash 2>/dev/null
/etc/init.d/openclash restart >/dev/null 2>&1
sleep 10
ps w | grep -E '[c]lash_meta|[o]penclash.sh' | head -4
echo "== 端口 =="
netstat -lnt 2>/dev/null | grep -E ':7890|:7891|:7892|:7893|:9090' | head -6
echo "== API =="
curl -s -o /dev/null -m 5 -w "  9090: %{http_code}\n" http://127.0.0.1:9090/
