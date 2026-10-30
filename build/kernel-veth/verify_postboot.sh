#!/bin/sh
echo "===== 0. system ====="
date; uptime; uname -r
echo
echo "===== 1. veth module (boot persistence) ====="
lsmod | grep '^veth' || echo "VETH NOT LOADED"
ls -l /lib/modules/$(uname -r)/veth.ko /etc/rc.d/S98kp-veth 2>/dev/null
echo
echo "===== 2. dockerd / bridge ====="
ps w | grep '[d]ockerd' | head -2
docker network ls 2>&1
ip -4 addr show docker0 2>&1 | head -3
echo
echo "===== 3. DNS bypass rules (after OpenClash/firewall boot) ====="
iptables -t nat -S PREROUTING | head -5
echo
echo "===== 4. container bridge test ====="
docker rm -f kpweb2 >/dev/null 2>&1
docker run -d --name kpweb2 -p 18081:80 busybox:latest sh -c 'mkdir -p /www && echo bridge-postboot-ok > /www/index.html && httpd -f -p 80 -h /www' >/dev/null 2>&1
sleep 2
echo "  ip: $(docker inspect kpweb2 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)"
echo -n "  curl 192.168.66.1:18081 -> "; curl -s -m 5 http://192.168.66.1:18081/ || echo FAIL
echo
echo -n "  container DNS (baidu) -> "; docker run --rm busybox:latest wget -qO- -T 10 http://www.baidu.com/ 2>&1 | head -c 40
echo
echo -n "  container outbound router -> "; docker exec kpweb2 wget -qO- -T 5 http://192.168.66.1/ 2>&1 | head -c 40
echo
docker rm -f kpweb2 >/dev/null 2>&1
echo
echo "===== 5. docker info bridge ====="
docker info 2>/dev/null | grep -E 'Server Version|Storage Driver|Cgroup Version|Network:' | head -5
echo
echo "===== 6. iStore fix still present ====="
ls /lib/apk/meta/ 2>/dev/null
echo
echo "===== 7. docker page patched text ====="
grep -c '自编译 <strong>veth' /overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_docker.htm 2>/dev/null
echo
echo "===== 8. daemon config ====="
cat /etc/docker/daemon.json
echo
echo "===== 9. disk ====="
df -h /overlay | tail -1
