#!/bin/sh
echo "== 源里带 speed 的包 =="
opkg list 2>/dev/null | grep -i 'speed' | head -10 || echo "  无"

echo "== 源里 app- 开头的（前 25）=="
opkg list 2>/dev/null | grep '^app-' | awk '{print $1}' | head -25

echo "== 直接尝试安装几种可能的包名 =="
for pkg in app-ocspeed ocspeed luci-app-ocspeed; do
	echo "--- $pkg ---"
	opkg install "$pkg" 2>&1 | tail -3
done

echo "== 备份清单里 ocspeed 相关条目 =="
grep -i 'ocspeed' /tmp/px/etc/kp-restore/packages.txt 2>/dev/null || echo "  （清单文件已清理）"
