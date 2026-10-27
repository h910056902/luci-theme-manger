#!/bin/sh
echo "== 写入 UCI =="
uci set dockerd.globals.alt_config_file='/etc/docker/daemon.json'
uci set dockerd.globals.data_root='/overlay/docker'
uci commit dockerd
uci show dockerd | grep -E 'alt_config_file|data_root'

echo "== 重启 dockerd =="
/etc/init.d/dockerd restart >/dev/null 2>&1
i=0
while [ $i -lt 8 ]; do i=$((i+1)); sleep 3; pidof dockerd >/dev/null 2>&1 && break; done
pidof dockerd >/dev/null 2>&1 && echo "  PID=$(pidof dockerd)" || { echo "  未启动"; logread | grep -i docker | tail -6; }

echo "== 生效配置 =="
ps w | grep '[/]usr/bin/dockerd' | head -1
readlink -f /tmp/dockerd/daemon.json 2>/dev/null
docker info 2>/dev/null | sed -n '/Registry Mirrors/,+3p'
docker info 2>/dev/null | grep -E 'Docker Root Dir|Storage Driver' | head -2
