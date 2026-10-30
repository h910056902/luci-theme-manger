#!/bin/sh
# KP-WIZARD v1 验证：页面渲染 / 聚合状态 / 日志端点 / 写操作校验（不实际切卡、不实际更新订阅）
B="http://192.168.66.1:8080/cgi-bin/luci/admin/network_guide/network"
echo "== 0. 表单登录 =="
SETC=$(curl -s -i -m 20 -d "luci_username=root&luci_password=admin" "http://192.168.66.1:8080/cgi-bin/luci/admin/status/details" | grep -i "^Set-Cookie:" | grep -o "sysauth=[0-9a-fA-F]*" | head -1)
[ -n "$SETC" ] || { echo "LOGIN_FAIL"; exit 1; }
echo "  cookie: ${SETC:0:24}..."

echo "== 1. 页面渲染 =="
curl -s -m 25 -H "Cookie: $SETC" "$B" -o /tmp/kp-wiz-page.html -w "http=%{http_code} size=%{size_download}\n"
for p in 'card-wifi' 'card-sim' 'card-oc' 'kp-wiz-state' '网络设置向导' 'mwrt-wifi' 'oc-go'; do
	printf '  %-16s %s\n' "$p" "$(grep -c "$p" /tmp/kp-wiz-page.html)"
done

echo "== 2. 聚合状态 refresh =="
curl -s -m 25 -H "Cookie: $SETC" "$B?action=refresh" -o /tmp/kp-wiz-state.json -w "http=%{http_code}\n"
grep -o '"ok":true' /tmp/kp-wiz-state.json | head -1
echo "  sim: $(grep -o '"sim":{[^}]*' /tmp/kp-wiz-state.json | head -c 200)"
echo "  oc.config: $(grep -o '"config":"[^"]*"' /tmp/kp-wiz-state.json | head -2)"
echo "  wifi 条数: $(grep -o '"section":"[^"]*"' /tmp/kp-wiz-state.json | wc -l)"

echo "== 3. oc_log 端点 =="
curl -s -m 25 -H "Cookie: $SETC" "$B?action=oc_log" | head -c 260
echo

echo "== 4. 写操作校验（不实际执行） =="
printf '  无 XHR 头:    '; curl -s -m 15 -o /dev/null -w '%{http_code}\n' -H "Cookie: $SETC" -d "sim=99" "$B?action=sim_switch"
printf '  sim=99:       '; curl -s -m 15 -H "Cookie: $SETC" -H "X-Requested-With: XMLHttpRequest" -d "sim=99" "$B?action=sim_switch"
echo
printf '  sim=当前卡:   '; CUR=$(grep -o '"cur":[0-9]*' /tmp/kp-wiz-state.json | head -1 | grep -o '[0-9]*'); curl -s -m 15 -H "Cookie: $SETC" -H "X-Requested-With: XMLHttpRequest" -d "sim=$CUR" "$B?action=sim_switch"
echo
printf '  oc_sub 坏址:  '; curl -s -m 15 -H "Cookie: $SETC" -H "X-Requested-With: XMLHttpRequest" --data-urlencode "url=ftp://bad" "$B?action=oc_sub"
echo
echo VERIFY_DONE
