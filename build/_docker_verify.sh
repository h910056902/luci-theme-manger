#!/bin/sh
echo "== 引擎信息 =="
docker info 2>/dev/null | grep -E 'Server Version|Storage Driver|Docker Root Dir|Registry Mirrors' | sed 's/^/  /'
docker info 2>/dev/null | grep -A3 'Registry Mirrors' | tail -3 | sed 's/^/    /'

echo "== 镜像 =="
docker images 2>/dev/null | head -4

echo "== 运行 =="
docker run --rm hello-world 2>&1 | grep -E 'Hello from Docker|This message' | head -2

echo "== 存储位置 =="
for d in /mnt/storage/data/docker /overlay/docker /var/lib/docker; do
	[ -d "$d" ] && echo "  $d -> $(du -sm "$d" 2>/dev/null | cut -f1) MB"
done

echo "== 进程 =="
ps w | grep -E '[d]ockerd$|[c]ontainerd$' | sed 's/^/  /' | head -3
echo "  dockerd pid: $(pidof dockerd)"
echo "  containerd pid: $(pidof containerd)"

echo "== 开机自启 =="
ls /etc/rc.d/ | grep -E 'dockerd|containerd' | sed 's/^/  /'

echo "== daemon.json 生效检查 =="
readlink -f /tmp/dockerd/daemon.json 2>/dev/null | sed 's/^/  /'
