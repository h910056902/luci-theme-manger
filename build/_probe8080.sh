#!/bin/sh
# 8080 探活（用实例实际监听地址，不是 127.0.0.1）
HOST=192.168.66.1
for u in / /cgi-bin/luci /cgi-bin/luci/admin/status/details /cgi-bin/luci/admin/status/cellular; do
    code=$(curl -s -m 10 -o /dev/null -w '%{http_code}' "http://$HOST:8080$u")
    size=$(curl -s -m 10 "http://$HOST:8080$u" | wc -c)
    echo "$u -> HTTP $code, ${size}B"
done
echo "--- login page head ---"
curl -s -m 10 "http://$HOST:8080/cgi-bin/luci" | head -c 240
echo
echo "--- listen ---"
netstat -lntp 2>/dev/null | grep 8080
