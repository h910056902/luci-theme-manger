#!/bin/sh
B=https://mirror.sjtu.edu.cn/openwrt/releases/23.05.5/packages/aarch64_cortex-a53/packages
W=/overlay/lsdl
mkdir -p "$W"
cd "$W" || exit 1

f=$(gunzip -c /tmp/P.gz 2>/dev/null | awk '/^Package: libseccomp$/{p=1} /^Filename: /{if(p){print $2; p=0}}' | head -1)
echo "  包名: ${f:-未找到}"
[ -n "$f" ] || exit 1

curl -sL -C - -m 90 -o "$W/libseccomp.ipk" "$B/$f" 2>/dev/null
ls -l "$W/libseccomp.ipk"

tar -xzf "$W/libseccomp.ipk" ./data.tar.gz && tar -xzf ./data.tar.gz -C /
echo "== 安装后 =="
ls -l /usr/lib/libseccomp.so* 2>/dev/null | head -3

echo "== runc 复检 =="
/usr/sbin/runc --version 2>&1 | head -2

echo "== 重启 docker 并跑容器 =="
/etc/init.d/dockerd restart >/dev/null 2>&1
i=0
while [ $i -lt 6 ]; do i=$((i+1)); sleep 3; pidof dockerd >/dev/null 2>&1 && break; done
docker run --rm --network host hello-world 2>&1 | grep -E 'Hello from Docker|rror' | head -3
