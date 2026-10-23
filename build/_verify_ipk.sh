#!/bin/sh
IPK=/tmp/nradio-luci-8080_20261024-2_all.ipk
W=/tmp/ipkchk
rm -rf "$W"; mkdir -p "$W"
tar -xzf "$IPK" -C "$W" 2>/dev/null || { echo "解包失败"; exit 1; }

echo "== data.tar.gz 里的系统脚本 =="
tar -tzf "$W/data.tar.gz" 2>/dev/null | grep -E 'kpsmsfwd|kp8080-listen'

echo "== postinst 是否处理 kpsmsfwd =="
tar -xzf "$W/control.tar.gz" -C "$W" 2>/dev/null
grep -c kpsmsfwd "$W/postinst" 2>/dev/null || echo 0

echo "== 包内短信页是否含转发卡片 =="
tar -xzOf "$W/data.tar.gz" ./overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_sms.htm 2>/dev/null | grep -c 'sms_fwd_set'
echo DONE
