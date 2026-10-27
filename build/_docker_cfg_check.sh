#!/bin/sh
echo "== dockerd 启动参数 =="
ps w | grep '[/]usr/bin/dockerd' | head -2

echo "== UCI =="
uci show dockerd 2>/dev/null | head -12

echo "== docker info 镜像加速 =="
docker info 2>/dev/null | sed -n '/Registry Mirrors/,+3p'

echo "== 实际读取的配置文件 =="
for f in /tmp/dockerd/daemon.json /etc/docker/daemon.json /etc/config/dockerd; do
	[ -f "$f" ] && { echo "  --- $f ---"; head -12 "$f"; }
done
