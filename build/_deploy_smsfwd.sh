#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-smsfwd-$TS
mkdir -p "$BAK"
cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
cp "$D/usr/lib/lua/luci/view/admin_status/nradio_sms.htm" "$BAK/sms.htm" 2>/dev/null
echo "BAK=$BAK"

# 去 CR（Windows 写入的脚本 CRLF 会让 busybox 报语法错）
for f in /tmp/_up_kpsmsfwd /tmp/_up_kpsmsfwd_init; do
	if [ -f "$f" ]; then
		tr -d '\r' < "$f" > "$f.lf" && mv "$f.lf" "$f"
	fi
done

cp /tmp/_up_kpsmsfwd /usr/bin/kpsmsfwd
chmod 755 /usr/bin/kpsmsfwd
cp /tmp/_up_kpsmsfwd_init /etc/init.d/kpsmsfwd
chmod 755 /etc/init.d/kpsmsfwd

cp /tmp/_up_luci "$D/www/cgi-bin/luci"
cp /tmp/_up_sms.htm "$D/usr/lib/lua/luci/view/admin_status/nradio_sms.htm"
chmod 755 "$D/www/cgi-bin/luci"
chmod 644 "$D/usr/lib/lua/luci/view/admin_status/nradio_sms.htm"

echo "== 语法 =="
lua -e "assert(loadfile('/usr/bin/kpsmsfwd'))" && echo SMSFWD_LUA_OK
sh -n /etc/init.d/kpsmsfwd && echo INIT_OK
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" || { echo CGI_SYNTAX_FAIL; exit 1; }

echo "== 初始化配置 =="
[ -f /etc/config/kpsmsfwd ] || printf "config main 'main'\n\toption enable '0'\n\toption interval '20'\n\toption url ''\n" > /etc/config/kpsmsfwd
[ -f /etc/kpsmsfwd.body ] || printf '{"sender":"{sender}","text":"{text}","time":"{time}"}' > /etc/kpsmsfwd.body
/etc/init.d/kpsmsfwd enable
/etc/init.d/kpsmsfwd restart
sleep 2
echo "== 进程 =="
ps w | grep '[k]psmsfwd' | head -2

rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
/etc/init.d/uhttpd restart >/dev/null 2>&1
sleep 2

SID=$(ubus call session login '{"username":"root","password":"admin","timeout":600}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
echo "== sms_fwd_get =="
curl -s -m 10 -H "Cookie: sysauth=$SID" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/sms?action=sms_fwd_get"
echo
echo "== 日志 =="
tail -3 /tmp/kpsmsfwd.log 2>/dev/null
echo DONE
