#!/bin/sh
echo "== 代理（HTTP 目标）=="
curl -s -o /dev/null -m 10 -x http://127.0.0.1:7890 -w "  gstatic204: %{http_code}\n" http://www.gstatic.com/generate_204
echo "== 代理（HTTPS 目标）=="
curl -s -o /dev/null -m 15 -x http://127.0.0.1:7890 -w "  github: %{http_code}\n" https://github.com
curl -s -o /dev/null -m 15 -x http://127.0.0.1:7890 -w "  google: %{http_code}\n" https://www.google.com
echo "== 出口 IP（直连 vs 代理）=="
echo -n "  直连: "; curl -s -m 8 http://ip.3322.net 2>/dev/null | head -1
echo -n "  代理: "; curl -s -m 15 -x http://127.0.0.1:7890 http://ip.3322.net 2>/dev/null | head -1
echo "== 订阅节点数 =="
grep -c 'name:' /etc/openclash/e_bbydy.yaml 2>/dev/null
echo "== 核心版本 =="
/etc/openclash/clash -v 2>&1 | head -2
