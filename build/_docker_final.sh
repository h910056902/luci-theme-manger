#!/bin/sh
echo "== 调整 daemon.json：关闭 bridge（内核无 veth）=="
cat > /etc/docker/daemon.json <<'EOF'
{
  "data-root": "/mnt/storage/data/docker",
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

echo "== 重启 =="
/etc/init.d/dockerd restart >/dev/null 2>&1
sleep 6
pidof dockerd >/dev/null 2>&1 && echo "  dockerd OK $(pidof dockerd)" || echo "  dockerd 启动失败"

echo "== 复测（host 网络）=="
docker run --rm --network host hello-world 2>&1 | grep -E 'Hello from Docker' | head -1
echo "== 引擎摘要 =="
docker info 2>/dev/null | grep -E 'Server Version|Storage Driver|Docker Root Dir' | sed 's/^/  /'
echo "== 已装组件 =="
opkg list-installed 2>/dev/null | grep -E '^(dockerd|containerd|runc|libnetwork|tini|libseccomp|docker) ' | sed 's/^/  /'
