#!/bin/sh
# 部署蜂窝页升级（邻区表 + 质量分布直方图），带备份、语法校验、登录态实测
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-cell-$TS
mkdir -p "$BAK"
cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
cp "$V/nradio_cellular.htm" "$BAK/nradio_cellular.htm" 2>/dev/null
echo "BAK=$BAK"

cp /tmp/_up_luci "$D/www/cgi-bin/luci"
cp /tmp/_up_cellular.htm "$V/nradio_cellular.htm"
chmod 755 "$D/www/cgi-bin/luci"
chmod 644 "$V/nradio_cellular.htm"

if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
    cp "$BAK/luci" "$D/www/cgi-bin/luci"
    cp "$BAK/nradio_cellular.htm" "$V/nradio_cellular.htm"
    echo "SYNTAX_FAIL"
    cat /tmp/kpc-syntax.err
    exit 1
fi
echo "SYNTAX_OK"
ls -l "$D/www/cgi-bin/luci" "$V/nradio_cellular.htm"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

echo "== 登录 8080 =="
rm -f /tmp/kp-cookie.txt
curl -s -m 10 -c /tmp/kp-cookie.txt -o /dev/null "http://192.168.66.1:8080/cgi-bin/luci"
CODE=$(curl -s -m 10 -b /tmp/kp-cookie.txt -c /tmp/kp-cookie.txt -o /dev/null -w '%{http_code}' -d "luci_username=root&luci_password=admin" "http://192.168.66.1:8080/cgi-bin/luci")
echo "login_http=$CODE"
grep -c sysauth /tmp/kp-cookie.txt

echo "== action=stats =="
curl -s -m 15 -b /tmp/kp-cookie.txt "http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular?action=stats" | head -c 800
echo
echo "== action=neighbor =="
curl -s -m 25 -b /tmp/kp-cookie.txt "http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular?action=neighbor" | head -c 1000
echo
echo "== 页面可访问 =="
curl -s -m 15 -b /tmp/kp-cookie.txt -o /dev/null -w "page=%{http_code}\n" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular"
echo "DONE"
