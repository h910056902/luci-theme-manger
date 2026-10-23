#!/bin/sh
D=/overlay/nradio-apps/openwrt-luci-8080
TS=$(date +%Y%m%d-%H%M%S)
BAK=/tmp/kpc-kpswap-$TS
mkdir -p "$BAK"
cp "$D/www/cgi-bin/luci" "$BAK/luci" 2>/dev/null
echo "BAK=$BAK"

# 去 CR
for f in /tmp/_up_kpswap_init /tmp/_up_luci; do
	[ -f "$f" ] && { tr -d '\r' < "$f" > "$f.lf" && mv "$f.lf" "$f"; }
done

cp /tmp/_up_kpswap_init /etc/init.d/kpswap
chmod 755 /etc/init.d/kpswap
cp /tmp/_up_luci "$D/www/cgi-bin/luci"
chmod 755 "$D/www/cgi-bin/luci"

echo "== 语法 =="
sh -n /etc/init.d/kpswap && echo INIT_OK
lua -e "assert(loadfile('$D/www/cgi-bin/luci'))" || { echo CGI_FAIL; exit 1; }

echo "== 启用开机挂载 =="
/etc/init.d/kpswap enable
ls -l /etc/rc.d/ | grep kpswap

echo "== 幂等性：重复 start 不应报错 =="
/etc/init.d/kpswap start; echo "start_rc=$?"
cat /proc/swaps

echo "== stop / start 往返 =="
/etc/init.d/kpswap stop; cat /proc/swaps | tail -1
/etc/init.d/kpswap start; cat /proc/swaps | tail -1

echo "== 接口状态 =="
rm -rf /tmp/luci-indexcache*
SID=$(ubus call session login '{"username":"root","password":"admin","timeout":600}' 2>/dev/null | grep -o '"ubus_rpc_session": *"[^"]*"' | cut -d'"' -f4)
curl -s -m 15 -H "Cookie: sysauth=$SID" \
	"http://192.168.66.1:8080/cgi-bin/luci/admin/status/cellular?action=swap"
echo
echo DONE
