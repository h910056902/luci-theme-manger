#!/bin/sh
echo "== apk 仓库 =="
cat /etc/apk/repositories 2>/dev/null || echo "  无 /etc/apk/repositories"
ls /etc/apk/ 2>/dev/null

echo "== apk update =="
apk update 2>&1 | tail -6

echo "== 找 docker 相关包 =="
for p in dockerd docker containerd runc docker-compose kmod-veth veth; do
	n=$(apk search -x "$p" 2>/dev/null | wc -l)
	echo "  $p -> $n"
done

echo "== 具体包名 =="
apk search -x 'docker*' 2>/dev/null | head -12
apk search -x 'kmod-*veth*' 2>/dev/null | head -5
