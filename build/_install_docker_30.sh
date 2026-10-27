#!/bin/sh
echo "== 1. 安装 docker（apk）=="
apk add --no-progress docker dockerd containerd runc 2>&1 | tail -8

echo "== 2. 校验 =="
command -v docker && docker --version
command -v dockerd && dockerd --version
command -v containerd && containerd --version 2>/dev/null | head -1

echo "== 3. 数据目录 =="
if [ -d /mnt/storage/data ]; then ROOT=/mnt/storage/data/docker; else ROOT=/overlay/docker; fi
mkdir -p "$ROOT"
echo "  data-root=$ROOT"

echo "== 4. daemon.json（无 veth → 关 bridge/iptables）=="
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "$ROOT",
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://dockerproxy.com",
    "https://mirror.ccs.tencentyun.com"
  ],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "2" },
  "bridge": "none",
  "iptables": false
}
EOF
cat /etc/docker/daemon.json

echo "== 5. UCI =="
uci -q get dockerd.globals >/dev/null 2>&1 || {
	uci set dockerd.globals=dockerd 2>/dev/null
}
uci set dockerd.globals.alt_config_file='/etc/docker/daemon.json'
uci commit dockerd 2>/dev/null
uci show dockerd 2>/dev/null | head -8

echo "== 6. 启动 =="
[ -x /etc/init.d/dockerd ] && {
	/etc/init.d/dockerd enable 2>/dev/null
	/etc/init.d/dockerd restart >/dev/null 2>&1
}
for i in 1 2 3 4 5 6; do
	sleep 4
	if pidof dockerd >/dev/null 2>&1; then echo "  dockerd OK pid=$(pidof dockerd)"; break; fi
	[ $i = 6 ] && { echo "  未启动"; logread 2>/dev/null | grep -i docker | tail -8; }
done

echo "== 7. 验证 =="
docker version 2>&1 | grep -E 'Version|API version' | head -4
docker info 2>/dev/null | grep -E 'Server Version|Storage Driver|Docker Root Dir' | head -3
