#!/bin/sh
echo "===== 1. iStore 数据链路（前端真的能拿到 132 个应用吗）====="
ID=$(cat /etc/.app_store.id 2>/dev/null)
ARCH=$(echo "$ID" | sed -n 's/.*"arch":"\([^"]*\)".*/\1/p')
UIDX=$(echo "$ID" | sed -n 's/.*"uid":"\([^"]*\)".*/\1/p')
echo "  arch=$ARCH uid=$UIDX"
curl -s -m 25 -o /tmp/store.json -w "  api http=%{http_code} size=%{size_download}\n" \
  "https://istore.istoreos.com/api/store/list?lang=zh-cn&arch=$ARCH&uid=$UIDX&version=0.2.1-r1&page=1&size=3"
head -c 200 /tmp/store.json 2>/dev/null; echo
echo "  total 字段: $(grep -o '"total":[0-9]*' /tmp/store.json 2>/dev/null | head -1)"

echo
echo "===== 2. 交换分区 ====="
free -m | tail -1
ls -lh /overlay/swapfile 2>/dev/null || echo "  无 swapfile"

echo
echo "===== 3. 磁盘占用 TOP ====="
du -sh /overlay/docker /overlay/kbuild /overlay/nradio-apps 2>/dev/null
df -h /overlay | tail -1
echo "  theme-backup 目录数: $(ls -d /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | wc -l)"
echo "  theme-backup 占用:   $(du -sh /overlay/nradio-apps/openwrt-luci-8080/theme-backup* 2>/dev/null | awk '{s+=$1} END {print s" (粗算)"}')"

echo
echo "===== 4. 日志体积 ====="
ls -lh /tmp/openclash.log /tmp/kp*.log /var/log/* 2>/dev/null | head -8
echo "  /tmp 占用: $(du -sh /tmp 2>/dev/null | awk '{print $1}')"

echo
echo "===== 5. Docker 引擎详情 ====="
ps w | grep '[d]ockerd' | head -1
cat /tmp/dockerd/daemon.json 2>/dev/null | head -12
echo "  daemon.json 源文件:"; cat /etc/docker/daemon.json | head -12
echo "  容器: $(ls /overlay/docker/containers 2>/dev/null | wc -l)"

echo
echo "===== 6. 开机自启项 ====="
for s in kp-veth dockerd openclash; do
  printf "  %-10s " "$s"; ls /etc/rc.d/ 2>/dev/null | grep -c "$s"
done

echo
echo "===== 7. 其它异常：僵尸 / D 状态 ====="
echo "  Z: $(ps w | awk '$4 ~ /Z/' | wc -l)   D: $(ps w | awk '$4 ~ /D/' | wc -l)"
echo "  总进程: $(ps w | wc -l)"

echo
echo "===== 8. cron ====="
cat /etc/crontabs/root
