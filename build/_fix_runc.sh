#!/bin/sh
killall -9 apk 2>/dev/null
killall -9 sh /tmp/_docker_fetch_bg.sh 2>/dev/null
sleep 1

echo "== 安装 libseccomp =="
apk add --no-progress libseccomp 2>&1 | tail -5
ls -l /usr/lib/libseccomp.so.2* 2>/dev/null

echo "== runc 复检 =="
/usr/sbin/runc --version 2>&1 | head -3

echo "== 重启 docker =="
/etc/init.d/dockerd restart >/dev/null 2>&1
i=0
while [ $i -lt 6 ]; do i=$((i+1)); sleep 3; pidof dockerd >/dev/null 2>&1 && break; done
pidof dockerd >/dev/null 2>&1 && echo "  dockerd PID=$(pidof dockerd)" || echo "  dockerd 未启动"

echo "== 跑容器（host）=="
docker run --rm --network host hello-world 2>&1 | grep -E 'Hello from Docker|error|Error' | head -3
