#!/bin/sh
# KP-WIZARD v1 部署：kp_wizard.htm(新) + www/cgi-bin/luci + mwrt-wifi(同步)
D=/overlay/nradio-apps/openwrt-luci-8080
V=$D/usr/lib/lua/luci/view/admin_status
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-wiz-$TS
mkdir -p "$BAK"
cp "$V/kp_wizard.htm" "$BAK/" 2>/dev/null
cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
cp "$D/www/cgi-bin/mwrt-wifi" "$BAK/mwrt-wifi" 2>/dev/null
echo "BAK=$BAK"

[ -f /tmp/_up_wizard.htm ] || { echo "MISS /tmp/_up_wizard.htm"; exit 1; }
[ -f /tmp/_up_luci ] || { echo "MISS /tmp/_up_luci"; exit 1; }
[ -f /tmp/_up_mwrtwifi ] || { echo "MISS /tmp/_up_mwrtwifi"; exit 1; }

echo "== 替换前 md5（对比 repo 同步状态） =="
md5sum "$D/www/cgi-bin/mwrt-wifi"

tr -d '\r' < /tmp/_up_wizard.htm > "$V/kp_wizard.htm"
tr -d '\r' < /tmp/_up_luci > "$D/www/cgi-bin/luci"
tr -d '\r' < /tmp/_up_mwrtwifi > "$D/www/cgi-bin/mwrt-wifi"
chmod 644 "$V/kp_wizard.htm"
chmod 755 "$D/www/cgi-bin/luci" "$D/www/cgi-bin/mwrt-wifi"

echo "== 语法 =="
if ! lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" 2>/tmp/kpc-syntax.err; then
	echo CGI_FAIL; cat /tmp/kpc-syntax.err
	cp "$BAK/luci" "$D/www/cgi-bin/luci"; chmod 755 "$D/www/cgi-bin/luci"
	exit 1
fi
echo CGI_SYNTAX_OK

echo "== 模板块语法 =="
lua /tmp/_wiz_tpl_check.lua || TPL_BAD=1

echo "== 引用检查 =="
echo "cgi 白名单: $(grep -c 'kp_wizard' "$D/www/cgi-bin/luci")"
echo "network 节点目标: $(grep -c 'template("admin_status/kp_wizard")' "$D/www/cgi-bin/luci")"

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2
[ -n "$TPL_BAD" ] && { echo TPL_CHECK_FAIL; exit 1; }
echo DONE
