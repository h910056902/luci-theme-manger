#!/bin/sh
BASE=https://downloads.openwrt.org/releases/21.02.7/packages/aarch64_cortex-a53/packages
cd /tmp || exit 1

echo "== 源里 libuv / libwebsockets / ttyd 文件名 =="
curl -s -m 20 "$BASE/" | grep -oE '(libuv1|libwebsockets-full|ttyd|libcap|libopenssl1\.1|zlib)_[^"]*\.ipk' | sort -u | head -10

echo "== 下载全部候选 =="
for f in $(curl -s -m 20 "$BASE/" | grep -oE '(libuv1|libwebsockets-full|ttyd|libcap)_[^"]*\.ipk' | sort -u); do
	[ -f "/tmp/$f" ] || curl -sL -m 90 -O "$BASE/$f" 2>/dev/null
done
ls -lh /tmp/libuv1* /tmp/libwebsockets* /tmp/ttyd* /tmp/libcap* 2>/dev/null

echo "== 按序安装 =="
for p in /tmp/libuv1_*.ipk /tmp/libcap_*.ipk /tmp/libwebsockets-full_*.ipk /tmp/ttyd_*.ipk; do
	[ -f "$p" ] || continue
	echo "--- $(basename "$p") ---"
	opkg install "$p" 2>&1 | tail -3
done

echo "== 校验 =="
opkg list-installed 2>/dev/null | grep -E 'ttyd|libwebsockets|libuv1' | head -5
command -v ttyd && ttyd --version 2>&1 | head -1

echo "== 启动 =="
/etc/init.d/ttyd enable 2>/dev/null
/etc/init.d/ttyd restart >/dev/null 2>&1
sleep 3
netstat -lnt 2>/dev/null | grep 7681
curl -s -o /dev/null -m 8 -w "  ttyd: %{http_code}\n" http://192.168.66.1:7681/
