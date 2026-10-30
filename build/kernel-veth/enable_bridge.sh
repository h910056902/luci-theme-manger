#!/bin/sh
# Enable Docker bridge networking after veth.ko is loaded.
# - backup /etc/docker/daemon.json
# - remove "bridge": "none" / "iptables": false
# - restart dockerd, verify docker0 + bridge network
set -u

echo "== 0. current daemon config =="
ls -l /etc/docker/daemon.json
cp -f /etc/docker/daemon.json /etc/docker/daemon.json.kp-hostonly.bak 2>/dev/null && echo "  backup -> /etc/docker/daemon.json.kp-hostonly.bak"

echo "== 1. write bridge-enabled daemon.json =="
cat > /etc/docker/daemon.json <<'EOF'
{
  "data-root": "/overlay/docker",
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com"
  ],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "2" }
}
EOF
cat /etc/docker/daemon.json

echo "== 2. ensure veth loaded =="
lsmod 2>/dev/null | grep -q '^veth' || insmod /lib/modules/$(uname -r)/veth.ko 2>/dev/null || insmod /overlay/kbuild/mod/veth.ko 2>/dev/null
lsmod 2>/dev/null | grep '^veth'

echo "== 3. restart dockerd =="
/etc/init.d/dockerd restart 2>&1 | tail -3
i=0
while [ $i -lt 15 ]; do
  i=$((i+1)); sleep 2
  docker info >/dev/null 2>&1 && break
done
docker info >/dev/null 2>&1 && echo "  daemon OK" || { echo "  daemon NOT ready"; ls -l /var/log/dockerd.log 2>/dev/null; tail -20 /var/log/dockerd.log 2>/dev/null; exit 1; }

echo "== 4. network state =="
docker network ls
ip -4 addr show docker0 2>&1 | head -3
echo "-- bridge sysctls --"
cat /proc/sys/net/bridge/bridge-nf-call-iptables 2>/dev/null
echo "-- iptables nat DOCKER --"
iptables -t nat -S 2>/dev/null | grep -E 'DOCKER|MASQUERADE' | head -8

echo "== 5. docker info summary =="
docker info 2>&1 | grep -E 'Server Version|Storage Driver|Cgroup|Network:|Init Binary' | head -8
