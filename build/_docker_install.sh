#!/bin/sh
# 依据 kunpeng-router-ai-skills/references/c2000u-docker.md 的 playbook
SD=/tmp/dockerstubs
mkdir -p "$SD"

echo "== 1. 装 kmod stub（先把 feed 索引移走，避免同名包截胡）=="
if [ -d /var/opkg-lists ]; then
	mv /var/opkg-lists /var/opkg-lists.off
	for f in "$SD"/*.ipk; do
		[ -f "$f" ] || continue
		printf "  %-46s " "$(basename "$f")"
		if opkg install --force-reinstall "$f" >/tmp/stub.log 2>&1; then echo OK; else echo "FAIL: $(tail -1 /tmp/stub.log)"; fi
	done
	rm -rf /var/opkg-lists
	mv /var/opkg-lists.off /var/opkg-lists
fi

echo "== 2. 装运行时依赖 =="
opkg update >/dev/null 2>&1 || true
for p in libseccomp libnetwork tini runc containerd dockerd; do
	printf "  %-14s " "$p"
	if opkg install "$p" >/tmp/pkg.log 2>&1; then echo OK; else echo "FAIL: $(grep -E 'cannot|Unknown' /tmp/pkg.log | head -1)"; fi
done

echo "== 3. 版本确认 =="
opkg list-installed 2>/dev/null | grep -E '^(dockerd|containerd|runc|libnetwork|tini|libseccomp)' | head -8
command -v dockerd && dockerd --version 2>&1 | head -1

echo "== 4. 配置：alt_config_file（否则 daemon.json 每次被覆盖）=="
mkdir -p /etc/docker
uci set dockerd.globals.alt_config_file='/etc/docker/daemon.json'
uci commit dockerd
cat > /etc/docker/daemon.json <<'EOF'
{
  "data-root": "/mnt/storage/data/docker",
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "2" }
}
EOF
[ -d /mnt/storage/data ] || sed -i 's#/mnt/storage/data/docker#/overlay/docker#' /etc/docker/daemon.json
echo "  daemon.json:"; head -4 /etc/docker/daemon.json

echo "== 5. 启动 =="
[ -x /etc/init.d/dockerd ] && {
	/etc/init.d/dockerd enable 2>/dev/null
	/etc/init.d/dockerd restart >/dev/null 2>&1
}
for i in 1 2 3 4 5 6; do
	sleep 4
	if pidof dockerd >/dev/null 2>&1; then echo "  dockerd 运行中: $(pidof dockerd)"; break; fi
	[ $i = 6 ] && { echo "  dockerd 未起来"; logread 2>/dev/null | grep -i docker | tail -6; }
done

echo "== 6. 验证 =="
docker version 2>&1 | head -6
docker info 2>&1 | grep -E 'Server Version|Storage Driver|Docker Root Dir|Registry Mirrors' -A1 | head -8
