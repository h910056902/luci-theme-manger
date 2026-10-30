#!/bin/sh
F=/overlay/nradio-apps/openwrt-luci-8080/usr/lib/lua/luci/view/admin_status/nradio_details.htm
echo "===== 1. 轮询刷新的 URL（784-900 行里的 fetch）====="
sed -n '784,900p' "$F" | grep -n -B2 -A6 'fetch\|XMLHttp\|url' | head -40
echo
echo "===== 2. 蜂窝/SIM 区块（页面里的卡片）====="
grep -n -E '蜂窝|SIM|寂寞|sim|cellular|频段|频点|RSRP|RSRQ|SNR|信号' "$F" 2>/dev/null | head -20
echo
echo "===== 3. 8080 CGI 里的取数函数（initial_json / storage_pct 定义处）====="
C=/overlay/nradio-apps/openwrt-luci-8080/www/cgi-bin/luci
grep -n 'initial_json\|storage_pct\|kp_live_status\|function kp_status' "$C" 2>/dev/null | head -12
echo
echo "===== 4. Lua 侧蜂窝字段来源 ====="
grep -n -E 'AT\+|atsd_cli|kpcped|nrswitch|signal|rsrp|rsrq|sinr|cell_id|band' "$C" 2>/dev/null | head -20
