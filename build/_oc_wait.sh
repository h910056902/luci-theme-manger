#!/bin/sh
for i in 1 2 3 4 5 6; do
	sleep 10
	echo "--- 第 $i 次检查（等待 $((i*10))s）---"
	ps w | grep -E '[c]lash_meta|[o]penclash.sh|[r]c.common /etc/init.d/openclash' | head -3
	ports=$(netstat -lnt 2>/dev/null | grep -cE ':7890|:7892|:9090')
	echo "  监听端口数: $ports"
	[ "$ports" -gt 0 ] && break
done

echo
echo "== 最终状态 =="
ps w | grep -E '[c]lash_meta' | head -2
netstat -lnt 2>/dev/null | grep -E ':7890|:7891|:7892|:7893|:9090' | head -6
curl -s -o /dev/null -m 5 -w "  9090 API: %{http_code}\n" http://127.0.0.1:9090/
echo "== 日志尾部 =="
tail -25 /tmp/openclash.log 2>/dev/null
