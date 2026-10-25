#!/bin/sh
echo "== /etc/openclash 结构 =="
ls -la /etc/openclash/ 2>/dev/null | head -12
echo "== core =="
ls -la /etc/openclash/core/ 2>/dev/null || echo "  无 core 目录"
echo "== 恢复包里 core 相关 =="
mkdir -p /tmp/ocd && cd /tmp/ocd || exit 1
IPK=$(ls -t /overlay/kp-restore-*.ipk | head -1)
tar -xzf "$IPK" data.tar.gz 2>/dev/null
tar -tzvf data.tar.gz 2>/dev/null | grep -E 'openclash/(core|GeoSite)' | head -6
echo "== 启动试跑 =="
/etc/init.d/openclash stop >/dev/null 2>&1
sleep 1
/etc/init.d/openclash start 2>&1 | head -10
sleep 3
pidof openclash >/dev/null 2>&1 && echo "  运行中 $(pidof openclash)" || echo "  仍未运行"
echo "== 日志 =="
logread 2>/dev/null | grep -iE 'openclash|clash' | tail -8
rm -rf /tmp/ocd
