#!/bin/sh
echo "===== 1. ubus 里的蜂窝/SIM 相关对象 ====="
ubus list 2>/dev/null | grep -iE 'modem|sim|cellular|wwan|nr|lte|quectel|kpc' | head -15
echo
echo "===== 2. 现有驾驶舱的状态接口返回什么 ====="
rm -f /tmp/qc.ck
curl -s -c /tmp/qc.ck -o /dev/null -m 10 -d 'luci_username=root&luci_password=admin' "http://192.168.66.1/cgi-bin/luci/"
for u in "nradio-initial-status" "nradio-refresh-status"; do
  echo "--- /cgi-bin/luci/admin/status/$u ---"
  curl -s -b /tmp/qc.ck -m 10 "http://192.168.66.1:8080/cgi-bin/luci/admin/status/$u" 2>/dev/null | head -c 600
  echo
done
echo
echo "===== 3. 蜂窝大页（nradio_cellular.htm，134KB）的接口 ====="
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_cellular.htm
grep -oE "(/cgi-bin/[a-zA-Z0-9_/?=-]+|ubus call [a-z._]+ [a-z_]+)" "$F" 2>/dev/null | sort | uniq -c | sort -rn | head -15
echo
echo "===== 4. 厂商命令行工具（SIM 信息从哪来）====="
for b in kpcped nradio at-cmd modem_sms quectel-CM ubus; do
  command -v $b >/dev/null && echo "  $b: $(command -v $b)"
done
ls /usr/sbin/ 2>/dev/null | grep -iE 'modem|sim|cell|nr|at' | head -10
echo
echo "===== 5. 当前 SIM 实况（找个权威来源）====="
ubus call nradio status 2>/dev/null | head -c 400
ubus call cellular status 2>/dev/null | head -c 400
ls /sys/class/net/ | grep -iE 'usb|wwan|ppp' | head -5
