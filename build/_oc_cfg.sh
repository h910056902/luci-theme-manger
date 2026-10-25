#!/bin/sh
echo "== /etc/openclash 概览 =="
ls -ld /etc/openclash /etc/openclash/config 2>/dev/null
echo "== config 目录内容 =="
ls -la /etc/openclash/config/ 2>/dev/null | head -8
echo "== 磁盘 =="
df -h /etc /overlay /tmp 2>/dev/null
echo "== uci 路径 =="
uci -q get openclash.config.config_path
uci -q get openclash.config.config_reload
uci -q get openclash.config.enable
echo "== 是否是符号链接 =="
readlink -f /etc/openclash 2>/dev/null
echo "== 手动下载一次订阅，看能否落盘 =="
curl -sL -m 30 -A 'clash-verge/v2.4.5' -o /tmp/test_sub.yaml \
	'https://e.bbydy.org/api/bby/client/subscribe?token=aae6a0a85203674b697f43c7987160a4'
echo "  下载大小: $(wc -c < /tmp/test_sub.yaml 2>/dev/null)"
head -3 /tmp/test_sub.yaml 2>/dev/null
echo "== 复制到 config 目录 =="
cp /tmp/test_sub.yaml /etc/openclash/config/e_bbydy.yaml 2>&1 && echo "  写入成功" || echo "  写入失败"
ls -l /etc/openclash/config/ 2>/dev/null
echo "== 空间/挂载 =="
mount | grep -E ' /etc| /overlay' | head -3
