#!/bin/sh
# ipk 安装测试：备份 → 安装 → 校验包内容 → HTTP 探活
PKG=nradio-luci-8080
IPK=/tmp/nradio-luci-8080_20261022-1_all.ipk
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kp8080-backup-$TS.tgz

echo "== 1. 备份实例目录 =="
tar -czf "$BAK" -C /overlay/nradio-apps openwrt-luci-8080
ls -l "$BAK"

echo "== 2. 安装前状态 =="
opkg list-installed | grep nradio-luci || echo "NOT-INSTALLED"

echo "== 3. opkg install =="
opkg install "$IPK" 2>&1
echo "INSTALL_RC=$?"

echo "== 4. 安装后状态 =="
opkg list-installed | grep nradio-luci || echo "STILL-NOT-INSTALLED"
CNT=$(opkg files $PKG 2>/dev/null | wc -l)
echo "FILE_COUNT=$CNT"
opkg files $PKG 2>/dev/null | head -12

echo "== 5. 关键文件校验 =="
ls -l /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci
md5sum /overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci
ls -la /overlay/nradio-apps/openwrt-luci-8080/www/luci-static | head -14

echo "== 6. HTTP 探活 =="
for u in / /cgi-bin/luci /cgi-bin/luci/admin/status/details /cgi-bin/luci/admin/status/cellular; do
    code=$(curl -s -m 8 -o /dev/null -w '%{http_code}' "http://127.0.0.1:8080$u")
    echo "$u -> $code"
done

echo "== 7. uhttpd 8080 配置 =="
uci -q get uhttpd.openwrt8080.home
ps w | grep 8080 | grep -v grep | head -3
echo "DONE"
