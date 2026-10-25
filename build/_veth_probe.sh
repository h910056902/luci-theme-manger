#!/bin/sh
echo "== 内核与模块 =="
uname -r
ls /lib/modules/ 2>/dev/null
ls -l /lib/modules/$(uname -r)/veth.ko* 2>/dev/null || echo "  设备上没有 veth.ko"

echo "== 内核配置里的 VETH / 网络命名空间 =="
zcat /proc/config.gz 2>/dev/null | grep -E '^CONFIG_(VETH|NET_NS|BRIDGE|DUMMY|MACVLAN|VXLAN)=' || echo "  无 /proc/config.gz"

echo "== ikconfig 包（stub 是否覆盖了真模块）=="
ls -l /lib/modules/$(uname -r)/ 2>/dev/null | head -12
opkg list-installed 2>/dev/null | grep -E 'kmod-(veth|dm|nf-ipvs|br-netfilter|ikconfig|fs-btrfs)'

echo "== 现有网络能力 =="
ip link add kpv0 type veth peer name kpv1 2>&1 | head -2
ip link add kpd0 type dummy 2>&1 | head -2
ip link del kpd0 2>/dev/null
ip netns add kpns 2>&1 | head -2
ip netns del kpns 2>/dev/null

echo "== docker 当前配置 =="
grep -E 'bridge|iptables|data-root' /etc/docker/daemon.json 2>/dev/null
pidof dockerd && docker info 2>/dev/null | grep -E 'Server Version|Network:' | head -3
