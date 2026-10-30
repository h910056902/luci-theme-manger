#!/bin/sh
# Load freshly built veth.ko and verify veth pair creation + bridge connectivity.
echo "== 1. insmod =="
dmesg -c >/dev/null 2>&1
insmod /overlay/kbuild/mod/veth.ko
echo "insmod_rc=$?"
dmesg 2>/dev/null | tail -8
echo "== 2. lsmod =="
lsmod 2>/dev/null | grep veth
echo "== 3. veth pair test =="
ip link add kpvt0 type veth peer name kpvt1 2>&1
echo "add_rc=$?"
ip link show kpvt0 2>&1 | head -3
ip link del kpvt0 2>/dev/null && echo "pair_cleanup_ok"
echo "== 4. bridge creation test =="
ip link add kpbr0 type bridge 2>&1
echo "bridge_rc=$?"
ip link set kpbr0 down 2>/dev/null
ip link del kpbr0 2>/dev/null && echo "bridge_cleanup_ok"
echo "== 5. module info =="
ls -l /overlay/kbuild/mod/veth.ko
