#!/bin/sh
echo "== 1. 修 apk world（移除 dockerd/docker，避免 apk 事务被坏依赖卡死）=="
cp /etc/apk/world /tmp/world.bak
grep -v -E '^(dockerd|docker)$' /etc/apk/world > /tmp/world.new && mv /tmp/world.new /etc/apk/world
echo -n "  world 中 dockerd/docker 剩余: "
grep -c -E '^(dockerd|docker)$' /etc/apk/world
echo "  备份: /tmp/world.bak"

echo "== 2. 清理下载缓存 =="
du -sm /overlay/apkdl /overlay/ipkdl /overlay/apkx /overlay/lsdl /overlay/dockerpkg 2>/dev/null
rm -rf /overlay/apkdl /overlay/ipkdl /overlay/apkx /overlay/lsdl /overlay/dockerpkg
rm -f /overlay/*.log /overlay/*.state /overlay/dsmoke.* /overlay/dm.* /overlay/df.* /overlay/di.* /overlay/ipk.* /overlay/apkdl.* 2>/dev/null
df -h /overlay | tail -1

echo "== 3. 最终状态 =="
pidof dockerd >/dev/null 2>&1 && echo "  dockerd PID=$(pidof dockerd)" || echo "  dockerd 未运行"
docker version --format '  server {{.Server.Version}}' 2>/dev/null
docker images --format '  {{.Repository}}:{{.Tag}} {{.Size}}' 2>/dev/null
docker ps -a --format '  {{.Names}} {{.Status}}' 2>/dev/null
echo "== 4. apk 是否恢复 =="
apk add --no-progress --simulate libseccomp 2>&1 | tail -2
