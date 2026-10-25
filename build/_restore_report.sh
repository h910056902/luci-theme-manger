#!/bin/sh
# 等待后台恢复结束（最多 6 分钟）
n=0
while [ $n -lt 36 ]; do
	grep -q 'stage=done' /tmp/istore-restore.state 2>/dev/null && break
	n=$((n+1))
	sleep 10
done

echo "== 最终状态 =="
cat /tmp/istore-restore.state
echo
echo "== 统计 =="
echo "  成功: $(grep -c '^OK' /tmp/istore-restore.log 2>/dev/null)"
echo "  失败: $(grep -c '^FAIL' /tmp/istore-restore.log 2>/dev/null)"
echo "  当前已装包总数: $(opkg list-installed 2>/dev/null | wc -l)"

echo
echo "== 失败清单（按类别）=="
grep '^FAIL' /tmp/istore-restore.log 2>/dev/null | sed 's/^FAIL //' | while read -r p; do echo "  $p"; done | head -50

echo
echo "== 成功清单（最后 20）=="
grep '^OK' /tmp/istore-restore.log 2>/dev/null | sed 's/^OK   //' | tail -20

echo
echo "== 关键应用是否到位 =="
for p in docker dockerd luci-app-store istoreenhance luci-app-istoreenhance luci-app-shadowrt luci-app-arpbind ttyd luci-app-ocspeed; do
	c=$(opkg list-installed 2>/dev/null | grep -c "^$p ")
	printf "  %-26s %s\n" "$p" "$([ "$c" = "1" ] && echo 已装 || echo 未装)"
done
