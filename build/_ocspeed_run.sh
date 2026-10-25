#!/bin/sh
echo "== 手动跑一次测速 =="
/usr/libexec/openclash-helper/speedswitch.sh run 2>&1 | tail -12

echo "== 数据目录 =="
ls -lh /etc/openclash-helper/ 2>/dev/null | head -8

echo "== 日志 =="
tail -12 /var/log/ocspeed.log 2>/dev/null

echo "== 状态摘要 =="
[ -f /etc/openclash-helper/status.json ] && head -c 400 /etc/openclash-helper/status.json
echo

echo "== 控制器注册 =="
grep -o 'services/openclash/ocspeed' /tmp/luci-indexcache* 2>/dev/null | head -1 || echo "  缓存中未见（可能需要重新登录触发建树）"

echo "== 80 端口页面 =="
curl -s -o /dev/null -m 10 -w "  80 /admin/services/openclash/ocspeed = %{http_code}\n" \
	http://192.168.66.1/cgi-bin/luci/admin/services/openclash/ocspeed
