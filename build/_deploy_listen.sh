#!/bin/sh
# 部署「监听地址可配置」：CGI + 模板 + 两个新脚本
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-listen-$TS
mkdir -p "$BAK"

cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
cp "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm" "$BAK/cellular.htm" 2>/dev/null
echo "BAK=$BAK"

cp /tmp/_up_luci "$D/www/cgi-bin/luci"
cp /tmp/_up_cellular.htm "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"
chmod 755 "$D/www/cgi-bin/luci"

if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
    cp "$BAK/luci" "$D/www/cgi-bin/luci"
    cp "$BAK/cellular.htm" "$D/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm"
    echo "SYNTAX_FAIL"
    cat /tmp/kpc-syntax.err
    exit 1
fi
echo "SYNTAX_OK"

cp /tmp/_up_kp8080-listen /usr/bin/kp8080-listen
cp /tmp/_up_kp8080-init /etc/init.d/kp8080-listen
chmod 755 /usr/bin/kp8080-listen /etc/init.d/kp8080-listen

echo "== 脚本自检 =="
sh -n /usr/bin/kp8080-listen && echo "bin syntax ok"
sh -n /etc/init.d/kp8080-listen && echo "init syntax ok"

echo "== 初始化配置（默认自动跟随 LAN） =="
if [ -z "$(uci -q get kpnet.web.listen)" ]; then
    uci set kpnet.web.listen='auto'
    uci set kpnet.web.port='8080'
    uci commit kpnet
    echo "已写入 kpnet.web.listen=auto"
else
    echo "已存在：$(uci -q get kpnet.web.listen)"
fi

/etc/init.d/kp8080-listen enable 2>/dev/null && echo "已设为开机自启"
ls -l /etc/rc.d/ 2>/dev/null | grep kp8080

echo "== 解析结果 =="
/usr/bin/kp8080-listen resolve
echo "== 当前监听 =="
uci -q get uhttpd.openwrt8080.listen_http
netstat -lnt 2>/dev/null | grep 8080
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
echo "DONE"
