#!/bin/sh
PKG=$(ls -t /tmp/kp-backup-*.ipk 2>/dev/null | head -1)
echo "== 目标包 =="
ls -l "$PKG" 2>/dev/null || { echo "包不存在"; exit 1; }

echo "== 校验外层 tar 完整性 =="
tar -tzf "$PKG" 2>&1
echo -n "gzip 校验: "; gzip -t "$PKG" 2>&1 && echo OK || echo FAIL

echo "== 校验 data.tar.gz 完整性 =="
rm -rf /tmp/kpchk2 && mkdir -p /tmp/kpchk2
tar -xzf "$PKG" -C /tmp/kpchk2 2>/dev/null
echo -n "data 条目数: "; tar -tzf /tmp/kpchk2/data.tar.gz 2>/dev/null | wc -l
echo -n "data gzip: "; gzip -t /tmp/kpchk2/data.tar.gz 2>&1 && echo OK || echo FAIL
echo -n "内层 config.tar.gz: "; gzip -t /tmp/kpchk2/config.tar.gz 2>/dev/null && echo OK || echo "需解包判断"

echo "== 再装一次（观察是否偶发）=="
opkg install --force-reinstall "$PKG" 2>&1 | tail -8
echo -n "登记: "; opkg list-installed 2>/dev/null | grep -c '^kp-backup'
rm -rf /tmp/kpchk2
echo DONE
