#!/bin/sh
F=dockerd-29.6.1-r1.apk
P=releases/25.12-SNAPSHOT/packages/aarch64_cortex-a53/packages
for m in \
  "https://downloads.openwrt.org" \
  "https://mirrors.tuna.tsinghua.edu.cn/openwrt" \
  "https://mirrors.ustc.edu.cn/openwrt" \
  "https://mirror.sjtu.edu.cn/openwrt" \
  "https://mirrors.aliyun.com/openwrt" \
  "https://mirrors.cloud.tencent.com/openwrt" ; do
	code=$(curl -s -o /dev/null -m 15 -r 0-2047 -w '%{http_code}' "$m/$P/$F" 2>/dev/null)
	echo "  $code  $m"
done
