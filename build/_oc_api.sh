#!/bin/sh
echo "== 运行配置里的 API 设置 =="
grep -E '^(secret|external-controller|external-ui|bind-address)' /etc/openclash/e_bbydy.yaml 2>/dev/null
ls -l /etc/openclash/e_bbydy.yaml 2>/dev/null

echo "== uci 里的 dashboard / 密码 =="
uci show openclash 2>/dev/null | grep -E 'dashboard|password|secret|cn_port' | head -6

echo "== 尝试无鉴权 / 带 secret 访问 API =="
curl -s -o /dev/null -m 5 -w "  no-auth: %{http_code}\n" http://127.0.0.1:9090/version
SEC=$(grep -E '^secret:' /etc/openclash/e_bbydy.yaml 2>/dev/null | head -1 | sed "s/^secret:[[:space:]]*//;s/['\"]//g")
echo "  secret: ${SEC:-（空）}"
[ -n "$SEC" ] && curl -s -m 5 -H "Authorization: Bearer $SEC" http://127.0.0.1:9090/version | head -c 200
echo

echo "== 组（Selector）列表 =="
[ -n "$SEC" ] && curl -s -m 8 -H "Authorization: Bearer $SEC" http://127.0.0.1:9090/proxies \
	| tr ',' '\n' | grep -E '"type":"Selector"' | head -5
