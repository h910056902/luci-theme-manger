#!/bin/sh
# 在路由器上把 8080 LuCI 实例打成老式 ipk（gzip( tar( debian-binary, control.tar.gz, data.tar.gz ) )）
# 本固件 opkg 只认这种格式，ar 格式会报 Malformed package file。
set -e

PKG=nradio-luci-8080
# 版本号可由第一个参数注入；默认「日期-1」
VER=${1:-$(date +%Y%m%d)-1}
D=/overlay/nradio-apps/openwrt-luci-8080
W=/tmp/ipkbuild
OUT=/tmp/${PKG}_${VER}_all.ipk
R=$W/data/overlay/nradio-apps/openwrt-luci-8080

echo "== 清理暂存 =="
rm -rf $W
mkdir -p $W/data $W/control "$R/www/cgi-bin" "$R/www/luci-static" "$R/usr/lib/lua/luci/view"

echo "== 收集 www =="
if [ -f "$D/www/index.html" ]; then cp "$D/www/index.html" "$R/www/"; fi
for d in logo fontawesome; do
    if [ -d "$D/www/$d" ]; then cp -a "$D/www/$d" "$R/www/"; fi
done
for d in bootstrap router3d; do
    if [ -d "$D/www/luci-static/$d" ]; then cp -a "$D/www/luci-static/$d" "$R/www/luci-static/"; fi
done

echo "== 收集 cgi-bin（跳过 .bak） =="
for f in luci mwrt-wifi mwrt-svc; do
    if [ -f "$D/www/cgi-bin/$f" ]; then cp "$D/www/cgi-bin/$f" "$R/www/cgi-bin/$f"; fi
done
chmod 755 "$R/www/cgi-bin/"*

echo "== 收集视图（只 .htm） =="
cd "$D/usr/lib/lua/luci/view"
find . -type f -name '*.htm' | while read -r f; do
    d=${f%/*}
    mkdir -p "$R/usr/lib/lua/luci/view/$d"
    cp "$f" "$R/usr/lib/lua/luci/view/$f"
done
cd /

SIZE=$(du -sk "$W/data" | cut -f1)
echo "== 数据大小 ${SIZE}KB =="

cat > "$W/control/control" <<EOF
Package: $PKG
Version: $VER
Depends: libc
Source: nradio
Section: luci
Priority: optional
Architecture: all
Installed-Size: $SIZE
Maintainer: NRadio
Description: NRadio 8080 LuCI instance (private views, theme and CGI entry)
 8080 端口独立 LuCI 实例的私有覆盖层：视图模板、bootstrap 主题定制、
 cgi-bin/luci 入口与无线快速设置接口。共享静态资源由安装脚本按符号链接接入。
EOF

cat > "$W/control/postinst" <<'EOF'
#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
[ -d "$D" ] || exit 0

chmod 755 "$D/www/cgi-bin/luci" 2>/dev/null
chmod 755 "$D/www/cgi-bin/mwrt-wifi" 2>/dev/null
chmod 755 "$D/www/cgi-bin/mwrt-svc" 2>/dev/null

# 复用系统已有的静态资源，避免重复占用（argon 是本地相对链接）
if [ -d "$D/www/luci-static/bootstrap" ] && [ ! -e "$D/www/luci-static/argon" ]; then
    ln -s bootstrap "$D/www/luci-static/argon"
fi
for n in iform istore istorerouter linkeasefile natpierce nradio openclash quickstart resources; do
    if [ -e "/www/luci-static/$n" ] && [ ! -e "$D/www/luci-static/$n" ]; then
        ln -s "/www/luci-static/$n" "$D/www/luci-static/$n"
    fi
done

# 8080 uhttpd 实例（幂等）
if ! uci -q get uhttpd.openwrt8080 >/dev/null 2>&1; then
    LAN=$(uci -q get network.lan.ipaddr)
    [ -n "$LAN" ] || LAN=192.168.66.1
    uci set uhttpd.openwrt8080=uhttpd
    uci set uhttpd.openwrt8080.enabled=1
    uci set uhttpd.openwrt8080.listen_http="$LAN:8080"
    uci set uhttpd.openwrt8080.rfc1918_filter=1
    uci set uhttpd.openwrt8080.max_connections=20
    uci set uhttpd.openwrt8080.network_timeout=30
    uci set uhttpd.openwrt8080.http_keepalive=20
    uci set uhttpd.openwrt8080.tcp_keepalive=1
    uci set uhttpd.openwrt8080.max_requests=10
    uci set uhttpd.openwrt8080.script_timeout=3600
    uci set uhttpd.openwrt8080.home="$D/www"
    uci set uhttpd.openwrt8080.cgi_prefix=/cgi-bin
    uci commit uhttpd
fi

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
exit 0
EOF

cat > "$W/control/postrm" <<'EOF'
#!/bin/sh
# 只回收本包安装时创建的符号链接，不动用户数据
D=/overlay/nradio-apps/openwrt-luci-8080
for n in argon iform istore istorerouter linkeasefile natpierce nradio openclash quickstart resources; do
    if [ -L "$D/www/luci-static/$n" ]; then rm -f "$D/www/luci-static/$n"; fi
done
rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
exit 0
EOF
chmod 755 "$W/control/postinst" "$W/control/postrm"

echo "== 打包 =="
cd "$W"
echo "2.0" > debian-binary
tar -C "$W/control" -czf control.tar.gz .
tar -C "$W/data" -czf data.tar.gz .
tar -czf "$OUT" debian-binary control.tar.gz data.tar.gz
cd /

echo "== 结果 =="
ls -l "$OUT"
md5sum "$OUT"
echo "MD5=$(md5sum "$OUT" | cut -d' ' -f1)"
echo "PKG=$PKG"
echo "VER=$VER"
echo "BYTES=$(wc -c < "$OUT")"
