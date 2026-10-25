#!/bin/sh
echo "== 备份并改写软件源 =="
cp /etc/opkg/distfeeds.conf /tmp/distfeeds.bak-$(date +%H%M%S) 2>/dev/null
sed -i 's#releases/21\.02-SNAPSHOT/packages#releases/21.02.7/packages#g' /etc/opkg/distfeeds.conf
cat /etc/opkg/distfeeds.conf

echo "== opkg update =="
opkg update 2>&1 | tail -8

echo "== 索引大小 =="
ls -l /var/opkg-lists/ 2>/dev/null | awk '{print "  "$5" "$9}'

echo "== 抽查包是否可见 =="
for p in docker dockerd luci-lib-taskd coreutils ttyd; do
	n=$(opkg list 2>/dev/null | grep -c "^$p ")
	echo "  $p -> $n"
done
