#!/bin/sh
t() {
	code=$(curl -s -o /dev/null -m 12 -w '%{http_code}' "$1")
	size=$(curl -s -m 15 "$1" 2>/dev/null | wc -c)
	echo "  $code  ${size}B  $1"
}

echo "== iStore 各架构路径 =="
for a in aarch64_cortex-a53 aarch64 all; do
	for f in store nas_luci meta; do
		t "https://istore.istoreos.com/repo/$a/$f/Packages.gz"
	done
done

echo "== OpenWrt 21.02.7 官方源 =="
t "https://downloads.openwrt.org/releases/21.02.7/packages/aarch64_cortex-a53/packages/Packages.gz"
t "https://downloads.openwrt.org/releases/21.02.7/packages/aarch64_cortex-a53/base/Packages.gz"
t "https://downloads.openwrt.org/releases/21.02.7/packages/aarch64_cortex-a53/routing/Packages.gz"
t "https://downloads.openwrt.org/releases/21.02.7/targets/mediatek/mt7987/packages/Packages.gz"
