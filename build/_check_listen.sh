#!/bin/sh
echo "== 当前监听配置 =="
uci show uhttpd.openwrt8080 2>/dev/null | grep -E 'listen|home|enabled'
echo "== 本机 IPv4 地址 =="
ip -4 addr show 2>/dev/null | grep -E '^[0-9]+:|inet ' | sed 's/^[ \t]*//'
echo "== LAN 配置 =="
echo "lan.ipaddr=$(uci -q get network.lan.ipaddr)"
echo "lan.netmask=$(uci -q get network.lan.netmask)"
echo "== 192.168.100.1 是否存在 =="
ip -4 addr show 2>/dev/null | grep -q "192.168.100.1" && echo "存在" || echo "不存在（绑上去会失败）"
echo "== 是否有 kpnet.web 配置 =="
uci -q get kpnet.web.listen || echo "(未配置)"
echo "== 监听端口实际状态 =="
netstat -lnt 2>/dev/null | grep -E ':8080|:80 ' | head -5
echo "== 相关二进制 =="
ls -l /usr/bin/kp8080-listen 2>/dev/null || echo "kp8080-listen 不存在"
ls -l /etc/init.d/kp8080-listen 2>/dev/null || echo "init 脚本不存在"
