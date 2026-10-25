#!/bin/sh
echo "== 文件是否存在 =="
ls -l /tmp/kp-backup-*.tar.gz 2>/dev/null || echo "无"

echo "== stat 可用性 =="
command -v stat || echo "无 stat"

echo "== stat 输出 =="
stat -c '%s|%Y|%n' /tmp/kp-backup-*.tar.gz 2>&1 | head -3

echo "== 换成 ls 输出 =="
ls -l /tmp/kp-backup-*.tar.gz 2>&1 | head -3

echo "== wc 方式 =="
for f in /tmp/kp-backup-*.tar.gz; do
	[ -f "$f" ] || continue
	echo "$(wc -c < "$f")|$f"
done
