#!/bin/sh
echo "== 关键命令 =="
for c in jsonfilter iptables ip6tables nft curl wget dnsmasq ipset; do
	printf "  %-10s %s\n" "$c" "$(command -v $c 2>/dev/null || echo -)"
done
echo "== iptables 后端 =="
iptables -V 2>&1 | head -1
nft --version 2>&1 | head -1
echo "== 防火墙框架 =="
[ -x /sbin/fw4 ] && echo "  fw4 (nftables)"
[ -x /sbin/fw3 ] && echo "  fw3 (iptables)"
uci -q get firewall.@defaults[0].flow_offloading 2>/dev/null
echo "== tun 模块 =="
lsmod 2>/dev/null | grep -c tun
ls /dev/net/tun 2>/dev/null || echo "  无 /dev/net/tun"
echo "== 下载进度 =="
ls -l /tmp/mihomo.gz 2>/dev/null
