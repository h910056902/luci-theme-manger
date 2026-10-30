#!/bin/sh
# Persist veth.ko across reboots: install module + init script that loads it before dockerd.
set -u
K=$(uname -r)

echo "== 1. install veth.ko =="
mkdir -p /lib/modules/$K
cp -f /overlay/kbuild/mod/veth.ko /lib/modules/$K/veth.ko
chmod 644 /lib/modules/$K/veth.ko
ls -l /lib/modules/$K/veth.ko

echo "== 2. init script (load before dockerd) =="
cat > /etc/init.d/kp-veth <<'EOF'
#!/bin/sh /etc/rc.common
# KP-VETH v1: 本固件内核未编 CONFIG_VETH；这里加载自编译的 veth.ko，
# 让 Docker 的 bridge 网络可用。模块在 /lib/modules/$(uname -r)/veth.ko。
START=98
STOP=01

boot() {
	/sbin/insmod /lib/modules/$(uname -r)/veth.ko 2>/dev/null
}
start() {
	/sbin/insmod /lib/modules/$(uname -r)/veth.ko 2>/dev/null
}
stop() {
	/sbin/rmmod veth 2>/dev/null
}
EOF
chmod 755 /etc/init.d/kp-veth
/etc/init.d/kp-veth enable
ls -l /etc/rc.d/ | grep kp-veth

echo "== 3. simulate boot load =="
rmmod veth 2>/dev/null
lsmod 2>/dev/null | grep -c '^veth'
/etc/init.d/kp-veth start
echo "  after start:"
lsmod 2>/dev/null | grep '^veth'

echo "== 4. verify bridge still works after reload =="
ip link add kpvt9 type veth peer name kpvt9p 2>&1 && echo "  veth pair OK" && ip link del kpvt9
