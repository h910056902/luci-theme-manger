#!/bin/sh
LOG=/tmp/apk-docker.log
ST=/tmp/apk-docker.state
: > "$LOG"

say() { echo "$*" >> "$LOG"; echo "stage=$1" > "$ST"; }

say "stub"

# ---- 1. 造 4 个 kmod stub（源里根本没有这些包）----
rm -rf /tmp/stub && mkdir -p /tmp/stub
for p in kmod-veth kmod-nf-ipvs kmod-ipt-physdev kmod-fs-btrfs; do
	d=/tmp/stub/$p
	mkdir -p "$d"
	cat > "$d/.PKGINFO" <<EOF
pkgname = $p
pkgver = 0.0.1-r0
pkgdesc = stub: module absent in vendor kernel (satisfies dockerd dependency)
arch = aarch64
size = 0
EOF
	tar -czf "/tmp/$p-0.0.1-r0.apk" -C "$d" .PKGINFO
	say "stub $p -> $(wc -c < /tmp/$p-0.0.1-r0.apk) B"
done

say "install-stub"
apk add --allow-untrusted --no-progress /tmp/kmod-veth-0.0.1-r0.apk /tmp/kmod-nf-ipvs-0.0.1-r0.apk \
	/tmp/kmod-ipt-physdev-0.0.1-r0.apk /tmp/kmod-fs-btrfs-0.0.1-r0.apk >> "$LOG" 2>&1
say "stub-done rc=$?"

# ---- 2. 装 docker ----
say "install-docker"
apk add --no-progress docker dockerd containerd runc >> "$LOG" 2>&1
say "docker-done rc=$? dockerd=$(command -v dockerd || echo none)"

# ---- 3. 配置并启动 ----
ROOT=/overlay/docker
[ -d /mnt/storage/data ] && ROOT=/mnt/storage/data/docker
mkdir -p "$ROOT" /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "$ROOT",
  "registry-mirrors": ["https://docker.m.daocloud.io", "https://dockerproxy.com"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "2" },
  "bridge": "none",
  "iptables": false
}
EOF

uci -q get dockerd.globals >/dev/null 2>&1 || uci set dockerd.globals=dockerd 2>/dev/null
uci set dockerd.globals.alt_config_file='/etc/docker/daemon.json'
uci commit dockerd 2>/dev/null

say "start"
[ -x /etc/init.d/dockerd ] && /etc/init.d/dockerd enable 2>/dev/null && /etc/init.d/dockerd restart >> "$LOG" 2>&1
i=0
while [ $i -lt 10 ]; do
	i=$((i+1)); sleep 3
	pidof dockerd >/dev/null 2>&1 && break
done

if pidof dockerd >/dev/null 2>&1; then
	say "done pid=$(pidof dockerd)"
else
	say "failed"
	logread 2>/dev/null | grep -i docker | tail -10 >> "$LOG"
fi
