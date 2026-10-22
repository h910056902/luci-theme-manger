#!/bin/sh
cd /tmp || exit 1
rm -rf /tmp/c7 && mkdir -p /tmp/c7
tar -xzf /tmp/nradio-luci-8080_20261022-7_all.ipk -C /tmp/c7 2>/dev/null || { echo "解包失败"; exit 1; }
echo "== -7 里的脚本路径 =="
tar -tzf /tmp/c7/data.tar.gz 2>/dev/null | grep -E 'kp8080' || echo "未找到 kp8080"
rm -rf /tmp/c7
