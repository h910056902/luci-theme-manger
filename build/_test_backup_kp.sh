#!/bin/sh
echo "== 可用空间 =="
df -h /overlay | tail -1

echo "== 启动备份 =="
/usr/bin/kp-recovery backup
sleep 3
/usr/bin/kp-recovery status

echo "== 等待完成（最多 90s）=="
i=0
while [ $i -lt 18 ]; do
	i=$((i+1))
	st=$(/usr/bin/kp-recovery status)
	echo "$st" | grep -q 'stage=done' && break
	sleep 5
done
/usr/bin/kp-recovery status

echo "== 产物 =="
d=$(/usr/bin/kp-recovery status | sed -n 's/.*dir=\([^ ]*\).*/\1/p')
echo "  dir=$d"
ls -lh "$d" 2>/dev/null | head -14
echo "== 校验和样例 =="
head -3 "$d/SHA256SUMS" 2>/dev/null
echo "== README =="
head -8 "$d/README.txt" 2>/dev/null
