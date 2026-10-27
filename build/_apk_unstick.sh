#!/bin/sh
echo "== 当前 apk 进程 =="
ps w | grep '[a]pk' | head -5

echo "== 等待锁释放（最多 90s）=="
i=0
while [ $i -lt 18 ]; do
	i=$((i+1))
	if ! ps w | grep -q '[a]pk add'; then echo "  无 apk add 进程"; break; fi
	sleep 5
done

echo "== 强杀残留 =="
killall -9 apk 2>/dev/null
sleep 1
ls -l /lib/apk/db/lock 2>/dev/null || echo "  无 lock 文件"

echo "== 已装情况 =="
command -v dockerd && dockerd --version || echo "  未安装 dockerd"
apk info -e dockerd 2>/dev/null && echo "  dockerd 已登记" || echo "  dockerd 未登记"
