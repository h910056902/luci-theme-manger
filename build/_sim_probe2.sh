#!/bin/sh
echo "===== 1. 驾驶舱 HTML 里怎么填 nradio-initial-status ====="
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_details.htm
grep -n -A3 'nradio-initial-status\|nradio-refresh' "$F" 2>/dev/null | head -30
echo
echo "===== 2. 驾驶舱引用的 JS 文件 ====="
grep -oE '<script[^>]*src="[^"]+"' "$F" 2>/dev/null | grep -oE 'src="[^"]+"' | sort -u
echo
echo "===== 3. ubus 对象方法清单 ====="
echo "--- kpcped ---"
ubus -v list kpcped 2>/dev/null | head -25
echo "--- nrswitch ---"
ubus -v list nrswitch 2>/dev/null | head -30
echo
echo "===== 4. kpcped 的 8888 HTTP 接口探测 ====="
for p in / /status /api/status /sim /api/sim /cellular; do
  code=$(curl -s -m 3 -o /tmp/kp8888.out -w "%{http_code}" "http://127.0.0.1:8888$p" 2>/dev/null)
  echo "  GET $p -> $code  $(head -c 120 /tmp/kp8888.out 2>/dev/null | tr -d '\n')"
done
echo
echo "===== 5. atsd_cli（AT 命令通道）====="
atsd_cli --help 2>&1 | head -8
echo "-- 试一条 AT --"
atsd_cli "AT+CPIN?" 2>&1 | head -5
