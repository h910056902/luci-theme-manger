#!/bin/sh
echo "== 1. 恢复 packages.txt（启用面板在线恢复）=="
rm -rf /tmp/rc && mkdir -p /tmp/rc && cd /tmp/rc || exit 1
IPK=$(ls -t /overlay/kp-restore-*.ipk 2>/dev/null | head -1)
if [ -n "$IPK" ]; then
	tar -xzf "$IPK" data.tar.gz 2>/dev/null
	mkdir -p /etc/kp-restore
	tar -xzf data.tar.gz ./etc/kp-restore/packages.txt -O > /etc/kp-restore/packages.txt 2>/dev/null
	echo "  packages.txt: $(wc -l < /etc/kp-restore/packages.txt 2>/dev/null) 行"
else
	echo "  恢复包不存在"
fi
rm -rf /tmp/rc

echo "== 2. 找 ttyd 安装包（21.02.7 官方 release）=="
BASE=https://downloads.openwrt.org/releases/21.02.7/packages/aarch64_cortex-a53/packages
curl -s -m 20 "$BASE/" 2>/dev/null | grep -o 'ttyd[^"]*\.ipk' | head -3
curl -s -m 20 "$BASE/" 2>/dev/null | grep -o 'libwebsockets[^"]*\.ipk' | head -2

echo "== 3. 直接尝试 opkg 安装 ttyd =="
opkg install ttyd 2>&1 | tail -3
