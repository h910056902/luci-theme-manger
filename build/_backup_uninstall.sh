#!/bin/sh
# 备份 8080 实例 → 卸载 ipk → 清商店登记与托管文件
# 保留：/root/backup 下的备份、/root/pkgs 下的 ipk、实例目录里的用户数据（theme-backup*、imei-history.log）
PKG=nradio-luci-8080
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
B=/root/backup

echo "== 1. 备份 =="
mkdir -p "$B"
tar -czf "$B/luci-8080-$TS.tgz" -C /overlay/nradio-apps openwrt-luci-8080
cp /etc/config/appcenter "$B/appcenter-$TS.conf" 2>/dev/null
cp /etc/config/uhttpd "$B/uhttpd-$TS.conf" 2>/dev/null
cp /root/pkgs/nradio-luci-8080_20261022-3_all.ipk "$B/" 2>/dev/null
echo "备份目录：$B"
ls -lh "$B"

echo "== 2. 卸载 ipk =="
opkg remove "$PKG" 2>&1
opkg list-installed | grep "$PKG" || echo "opkg: 已移除"

echo "== 3. 清商店登记 =="
i=0
while uci -q get appcenter.@package_list[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package_list[$i].name)
    if [ "$n" = "$PKG" ]; then uci delete appcenter.@package_list[$i]; continue; fi
    i=$((i + 1))
done
i=0
while uci -q get appcenter.@package[$i] >/dev/null 2>&1; do
    n=$(uci -q get appcenter.@package[$i].name)
    if [ "$n" = "$PKG" ]; then uci delete appcenter.@package[$i]; continue; fi
    i=$((i + 1))
done
uci commit appcenter
/etc/init.d/appcenter restart >/dev/null 2>&1
sleep 2
echo "商店残留条目数：$(ubus call appcenter list 2>/dev/null | grep -c "$PKG")"

echo "== 4. 清托管 ipk =="
rm -rf /www/pkgs /www/nradio-appstore/all/"$PKG"
rmdir /www/nradio-appstore/all /www/nradio-appstore 2>/dev/null
ls -d /www/pkgs /www/nradio-appstore 2>/dev/null || echo "托管目录已清理"

echo "== 5. 清临时文件 =="
rm -rf /tmp/ipkbuild /tmp/_up_luci /tmp/_up_cellular.htm
echo done

echo "== 6. 现状 =="
echo "-- 实例目录 --"
ls -la "$D" | head -12
echo "-- cgi-bin --"
ls -l "$D/www/cgi-bin" 2>/dev/null
echo "-- 8080 探活 --"
curl -s -m 8 -o /dev/null -w "/ -> %{http_code}\n" http://192.168.66.1:8080/
echo "-- 保留的 ipk --"
ls -lh /root/pkgs/*.ipk 2>/dev/null
echo "DONE"
