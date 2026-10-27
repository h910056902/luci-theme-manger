#!/bin/sh
echo "== 已装核对 =="
for p in docker dockerd containerd runc; do
	printf "  %-12s " "$p"
	apk info -e "$p" 2>/dev/null || echo "未装"
done

echo "== fetch 用法 =="
apk fetch --help 2>&1 | sed -n '1,25p'

echo "== dockerd 策略 =="
apk policy dockerd 2>&1 | head -8
