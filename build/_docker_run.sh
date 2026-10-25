#!/bin/sh
echo "== 运行 hello-world =="
docker run --rm hello-world 2>&1 | head -12

echo
echo "== 容器列表 =="
docker ps -a 2>/dev/null | head -3

echo "== 镜像 =="
docker images 2>/dev/null | head -3
