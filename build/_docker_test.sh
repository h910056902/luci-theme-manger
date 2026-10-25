#!/bin/sh
echo "== 拉取测试镜像 =="
timeout_pull() {
	timeout 120 docker pull "$1" 2>&1 | tail -4
}
if timeout_pull hello-world; then
	echo "  hello-world 拉取成功"
else
	echo "  直连失败，试 alpine"
	timeout_pull alpine:3.19
fi

echo "== 运行容器 =="
docker run --rm hello-world 2>&1 | head -6

echo "== 资源占用 =="
ps w | grep -E '[d]ockerd|[c]ontainerd' | awk '{printf "  %s RSS=%sKB\n", $5, $6}'
echo "== 磁盘 =="
df -h /mnt/storage/data 2>/dev/null | tail -1
du -sm /mnt/storage/data/docker 2>/dev/null
echo "== 自启 =="
ls -l /etc/rc.d/ | grep -E 'dockerd|containerd'
