#!/bin/sh
echo "== 1. CSS 是否落盘（ASCII 标记）=="
grep -c 'brand-primary:#1f6feb' /usr/lib/lua/luci/view/ocspeed.htm

echo "== 2. 恢复进度 =="
cat /tmp/istore-restore.state 2>/dev/null
echo

echo "== 3. 失败原因抽样 =="
echo "--- luci-lib-taskd ---"
opkg install luci-lib-taskd 2>&1 | tail -5
echo "--- docker ---"
opkg install docker 2>&1 | tail -5

echo "== 4. 源索引情况 =="
ls -l /var/opkg-lists/ 2>/dev/null | awk '{print "  "$5" "$9}'
echo "== 5. 某包是否在索引里 =="
grep -c '^Package: docker$' /var/opkg-lists/* 2>/dev/null | head -5
