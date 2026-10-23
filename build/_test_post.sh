#!/bin/sh
# 复现守护里的 webhook 投递方式，确认 curl 调用链可用
BODY='{"sender":"10086","text":"测试 test","time":"2026-10-24 00:15"}'
printf '%s' "$BODY" | curl -s -m 10 -o /dev/null -w 'post_http=%{http_code}\n' \
	-X POST -H 'Content-Type: application/json' \
	--data-binary @- 'http://192.168.66.1:8080/cgi-bin/luci'
echo "curl_rc=$?"
