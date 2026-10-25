#!/bin/sh
docker rm -f kp-demo >/dev/null 2>&1
docker run --name kp-demo --network host hello-world >/dev/null 2>&1
echo "== 容器 =="
docker ps -a --format '{{.Names}}|{{.Image}}|{{.Status}}'
echo "== 通过面板接口读 =="
B=http://127.0.0.1:8080
rm -f /tmp/kd2.ck
curl -s -c /tmp/kd2.ck -o /dev/null "$B/cgi-bin/luci/admin/status/docker"
curl -s -b /tmp/kd2.ck -m 12 "$B/cgi-bin/luci/admin/status/docker?action=docker&op=ps" | head -c 400
echo
