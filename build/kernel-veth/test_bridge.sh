#!/bin/sh
# Test Docker bridge networking after veth.ko is loaded and bridge enabled.
echo "== 0. veth module =="
lsmod | grep '^veth' || insmod /lib/modules/$(uname -r)/veth.ko 2>/dev/null || insmod /overlay/kbuild/mod/veth.ko

echo
echo "== 1. networks =="
docker network ls

echo
echo "== 2. run web container with published port =="
docker rm -f kpweb >/dev/null 2>&1
docker run -d --name kpweb -p 18080:80 busybox:latest sh -c 'mkdir -p /www && echo bridge-ok > /www/index.html && httpd -f -p 80 -h /www' >/dev/null 2>&1
sleep 2
echo "  container ip: $(docker inspect kpweb --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)"
echo "  port mapping: $(docker port kpweb 2>/dev/null)"
echo -n "  host curl 127.0.0.1:18080 -> "
curl -s -m 5 http://127.0.0.1:18080/ || echo FAIL
echo
echo -n "  host curl 192.168.66.1:18080 -> "
curl -s -m 5 http://192.168.66.1:18080/ || echo FAIL
echo

echo
echo "== 3. container outbound =="
echo -n "  container -> router 192.168.66.1: "
docker exec kpweb wget -qO- -T 6 http://192.168.66.1/ 2>&1 | head -c 60
echo
echo -n "  container -> internet (baidu): "
docker exec kpweb wget -qO- -T 8 http://www.baidu.com/ 2>&1 | head -c 60
echo

echo
echo "== 4. container-to-container =="
docker run -d --name kpcli busybox:latest sleep 30 >/dev/null 2>&1
IP=$(docker inspect kpweb --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
echo "  target ip: $IP"
docker exec kpcli ping -c1 -W2 "$IP" 2>&1 | head -3
docker exec kpcli wget -qO- -T 5 "http://$IP/" 2>&1 | head -c 40
echo

echo
echo "== 5. bridge state =="
ip -4 addr show docker0 2>&1 | head -3
cat /proc/sys/net/bridge/bridge-nf-call-iptables 2>/dev/null
iptables -t nat -S 2>/dev/null | grep -E 'DOCKER|MASQUERADE' | head -6

echo
echo "== 6. cleanup =="
docker rm -f kpweb kpcli >/dev/null 2>&1
docker ps -a --format '{{.Names}}' | head -5
