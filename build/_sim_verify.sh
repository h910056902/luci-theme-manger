#!/bin/sh
# KP-SIM-CARD v1 验证：页面渲染 / include 生效 / refresh 2s 缓存 / 副线路字段
B="http://192.168.66.1:8080/cgi-bin/luci"
echo "== 0. 表单登录（dispatcher 会话，POST 到目标页） =="
SETC=$(curl -s -i -m 20 -d "luci_username=root&luci_password=admin" "$B/admin/status/details" | grep -i "^Set-Cookie:" | grep -o "sysauth=[0-9a-fA-F]*" | head -1)
echo "  cookie: ${SETC:0:24}..."
[ -n "$SETC" ] || { echo "LOGIN_FAIL"; exit 1; }

echo "== 1. 页面渲染 =="
curl -s -m 25 -H "Cookie: $SETC" "$B/admin/status/details" -o /tmp/kp-sim-page.html -w "http=%{http_code} size=%{size_download}\n"
for p in 'class="hero"' 'data-nradio-hero="op"' 'data-nradio-temp' 'data-nradio-line2' 'h-more' 'mwrt-home-custom.css?v=2' 'nradio-initial-status'; do
	printf '  %-28s %s\n' "$p" "$(grep -c "$p" /tmp/kp-sim-page.html)"
done
echo "  卡片关键值: $(grep -o 'data-nradio-hero="op">[^<]*' /tmp/kp-sim-page.html | head -1)"

echo "== 2. refresh 2s 缓存（连发两次，_ts 应相同） =="
T1=$(curl -s -m 25 -H "Cookie: $SETC" "$B/admin/status/details?refresh=1")
T2=$(curl -s -m 25 -H "Cookie: $SETC" "$B/admin/status/details?refresh=1")
echo "  head: $(echo "$T1" | head -c 90)"
echo "  ts1=$(echo "$T1" | grep -o '"_ts":[0-9]*' | head -1) ts2=$(echo "$T2" | grep -o '"_ts":[0-9]*' | head -1)"
echo "  has_stats1=$(echo "$T1" | grep -c '"stats"') has_version1=$(echo "$T1" | grep -c '"version":"20261018-1"')"
echo "  len1=$(printf %s "$T1" | wc -c) len2=$(printf %s "$T2" | wc -c)"
echo "  l2_default_true=$(printf %s "$T1" | grep -o '"default_route":true' | wc -l)"

echo "== 3. 缓存文件 =="
ls -l /tmp/kp-live-cache.json 2>/dev/null || echo "  缓存文件缺失"
head -c 60 /tmp/kp-live-cache.json 2>/dev/null; echo

echo "== 4. 等 3s 缓存过期后再取（_ts 应更新） =="
sleep 3
T3=$(curl -s -m 25 -H "Cookie: $SETC" "$B/admin/status/details?refresh=1")
echo "  ts3=$(echo "$T3" | grep -o '"_ts":[0-9]*' | head -1)"
echo VERIFY_DONE
