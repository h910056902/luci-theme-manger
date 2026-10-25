#!/bin/sh
echo "== 全盘找 clash 内核 =="
find / -xdev \( -name 'clash_meta' -o -name 'clash*' -type f \) 2>/dev/null | grep -vE '^/proc|\.lua$|\.sh$|\.htm$|\.js$' | head -12

echo "== /usr/share/openclash 结构 =="
ls -la /usr/share/openclash/ 2>/dev/null | head -12
du -sm /usr/share/openclash/* 2>/dev/null | sort -nr | head -6

echo "== 包里 core 的 tar 条目（更宽的匹配）=="
mkdir -p /tmp/ocd2 && cd /tmp/ocd2 || exit 1
tar -xzf "$(ls -t /overlay/kp-restore-*.ipk | head -1)" data.tar.gz 2>/dev/null
tar -tvzf data.tar.gz 2>/dev/null | grep -E 'openclash/core|clash_meta' | head -6 || echo "  包内无 core"
rm -rf /tmp/ocd2

echo "== 系统架构 =="
uname -m
opkg print-architecture 2>/dev/null | head -3
