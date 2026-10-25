#!/bin/sh
echo "== 依次补 docker 依赖链 =="
for p in libdevmapper containerd runc dockerd docker-compose docker-lan-bridge; do
	echo "--- $p ---"
	opkg install "$p" 2>&1 | tail -3
done

echo "== 结果 =="
opkg list-installed 2>/dev/null | grep -E '^(docker|dockerd|containerd|runc|libdevmapper)' | head -8

echo "== 服务 =="
[ -x /etc/init.d/dockerd ] && /etc/init.d/dockerd enable 2>/dev/null && /etc/init.d/dockerd start 2>&1 | head -3
sleep 3
pidof dockerd >/dev/null 2>&1 && echo "  dockerd 运行中: $(pidof dockerd)" || echo "  dockerd 未运行"
