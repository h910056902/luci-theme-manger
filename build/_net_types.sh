#!/bin/sh
echo "== 相关模块文件 =="
ls /lib/modules/5.4.281/ 2>/dev/null | grep -E 'macvlan|ipvlan|vxlan|dummy|veth|tun'
echo "  （空 = 都没有）"

echo "== macvlan =="
ip link add link br-lan name kvm0 type macvlan mode bridge 2>&1 | head -2
ip link show kvm0 2>/dev/null | head -2
ip link del kvm0 2>/dev/null

echo "== ipvlan =="
ip link add link br-lan name kvi0 type ipvlan mode l2 2>&1 | head -2
ip link show kvi0 2>/dev/null | head -2
ip link del kvi0 2>/dev/null

echo "== vxlan =="
ip link add kvx0 type vxlan id 100 dstport 4789 2>&1 | head -2
ip link del kvx0 2>/dev/null

echo "== 已注册的 link 类型 =="
ls /sys/class/net/ 2>/dev/null | tr '\n' ' '
echo
grep -o 'veth\|dummy\|macvlan\|ipvlan' /proc/net/ptype 2>/dev/null | sort -u | tr '\n' ' '
echo
echo "== docker 支持的驱动 =="
docker info 2>/dev/null | grep -A1 'Plugins'
