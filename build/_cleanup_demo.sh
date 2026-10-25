#!/bin/sh
docker rm -f kp-demo >/dev/null 2>&1
echo -n "剩余容器: "
docker ps -a -q 2>/dev/null | wc -l
echo -n "镜像: "
docker images -q 2>/dev/null | wc -l
echo -n "dockerd: "
pidof dockerd || echo "未运行"
