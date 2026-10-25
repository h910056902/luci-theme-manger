#!/bin/sh
echo "== 内核 veth 支持 =="
modprobe veth 2>&1 | head -2
lsmod 2>/dev/null | grep -c veth
ip link add kpv0 type veth peer name kpv1 2>&1 | head -2
ip link del kpv0 2>/dev/null

echo "== host 网络运行 =="
docker run --rm --network host hello-world 2>&1 | head -8

echo "== 结果 =="
docker ps -a 2>/dev/null | head -3
