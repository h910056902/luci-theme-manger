#!/bin/sh
echo "== runc 位置 =="
ls -l /usr/bin/runc /usr/sbin/runc /usr/bin/docker-runc 2>/dev/null || echo "  未找到 runc"
echo "== daemon.json =="
cat /etc/docker/daemon.json 2>/dev/null || echo "  缺失"

echo "== 启动 dockerd =="
/etc/init.d/dockerd enable 2>/dev/null
/etc/init.d/dockerd restart 2>&1 | head -4
i=0
while [ $i -lt 8 ]; do
	i=$((i+1)); sleep 3
	pidof dockerd >/dev/null 2>&1 && break
done
pidof dockerd >/dev/null 2>&1 && echo "  PID=$(pidof dockerd)" || {
	echo "  未启动"; logread 2>/dev/null | grep -i docker | tail -8
}

echo "== 验证 =="
docker version 2>&1 | grep -E 'Version|API' | head -4
docker info 2>/dev/null | grep -E 'Server Version|Storage Driver|Docker Root Dir|Cgroup' | head -4
echo "== 容器/镜像 =="
docker ps -a -q 2>/dev/null | wc -l
docker images -q 2>/dev/null | wc -l
