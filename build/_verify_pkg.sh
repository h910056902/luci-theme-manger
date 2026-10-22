#!/bin/sh
IPK=/tmp/nradio-luci-8080_20261022-6_all.ipk
cd /tmp || exit 1
rm -rf /tmp/pkgchk
mkdir -p /tmp/pkgchk
tar -xzf "$IPK" -C /tmp/pkgchk 2>/dev/null || { echo "外层解包失败"; exit 1; }

echo "== 外层成员 =="
ls -l /tmp/pkgchk

echo "== data 里的新脚本 =="
tar -tzf /tmp/pkgchk/data.tar.gz 2>/dev/null | grep -E 'kp8080|init\.d' || echo "未找到"

echo "== postinst 关键行 =="
tar -xzf /tmp/pkgchk/control.tar.gz -C /tmp/pkgchk 2>/dev/null
grep -nE 'kp8080|kpnet' /tmp/pkgchk/postinst 2>/dev/null || echo "postinst 无相关行"

echo "== 文件总数 =="
tar -tzf /tmp/pkgchk/data.tar.gz 2>/dev/null | grep -vc '/$'
rm -rf /tmp/pkgchk
echo "DONE"
