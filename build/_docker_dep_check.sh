#!/bin/sh
echo "== A. 模拟安装 dockerd + docker（解析全部依赖，看真正缺什么）=="
apk add --simulate dockerd docker 2>&1 | grep -vE "^WARNING|^\[" | head -40

echo
echo "== B. 内核内建状态（=y 为内建，=m 为模块，无则不支持）=="
zcat /proc/config.gz 2>/dev/null | grep -E "CONFIG_(VETH|BRIDGE|BRIDGE_NETFILTER|NETFILTER_XT_PHYSDEV|NF_IPVS|DUMMY|VXLAN|MACVLAN|OVERLAY_FS|IP_NF_|NF_NAT|NET_SCH_INGRESS|NET_CLS_CGROUP|BLK_DEV_DM)="

echo
echo "== C. veth 实测 =="
modprobe veth 2>&1
echo "modprobe veth rc=$?"
ip link add dktest0 type veth peer name dktest1 2>&1
echo "ip link add veth rc=$?"
ip link del dktest0 2>&1

echo
echo "== D. 现有二进制来源核实 =="
opkg_list=$(apk list -I 2>/dev/null)
echo "$opkg_list" | grep -E "^(docker|dockerd|containerd|runc)-[0-9]" || echo "(dockerd/containerd/runc 未由 apk 安装 -> /usr/bin 下是手工解包版)"
ls -l /usr/bin/dockerd /usr/bin/docker /usr/bin/containerd /usr/sbin/runc 2>&1

echo
echo "== E. dockerd 29.6.1 包的容器运行时配套 =="
apk list 2>/dev/null | grep -E "^(containerd|runc|docker-init|tini)-[0-9]"
